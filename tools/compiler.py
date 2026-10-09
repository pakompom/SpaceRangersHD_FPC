"""Bootstrap the pinned FPC compiler and isolated platform runtimes."""

import hashlib
import json
import os
import platform
import re
import shutil
import subprocess
from pathlib import Path

from build_support import BuildStamp, run_step
from targets import ANDROID_MIN_API, ROOT, TARGETS, desktop_target, host_cpu

VENDOR = ROOT / "vendor/fpc"
WORK = ROOT / ".local/fpc"


def llvm_options(clang: str | Path = "clang") -> tuple[str, ...]:
    version = subprocess.check_output([str(clang), "--version"], text=True)
    match = re.search(r"clang version (\d+)", version)
    if match is None or int(match[1]) < 14:
        raise RuntimeError("Clang 14 or newer is required for the LLVM backend.")
    # The compiler supports LLVM 17 IR; older Clang needs its own IR dialect.
    return (f"-Clv{min(int(match[1]), 17)}.0",)


def source_revision() -> str:
    """Hash compiler inputs without rereading an unchanged vendored checkout."""
    digest = hashlib.sha256()
    # Packages are compiled from VENDOR by the game build, not compiler_cycle.
    names = ["compiler", "rtl", *sorted(path.name for path in VENDOR.glob("Makefile*"))]
    try:
        git = ["git", "-C", str(VENDOR)]
        toplevel = subprocess.check_output(
            [*git, "rev-parse", "--show-toplevel"], stderr=subprocess.DEVNULL
        )
        if Path(os.fsdecode(toplevel).strip()).resolve() != VENDOR.resolve():
            raise ValueError("The vendor directory is not a Git worktree.")
        digest.update(subprocess.check_output([*git, "ls-tree", "-z", "HEAD", "--", *names]))
        digest.update(
            subprocess.check_output(
                [
                    *git,
                    "diff",
                    "--binary",
                    "--no-ext-diff",
                    "--no-textconv",
                    "HEAD",
                    "--",
                    *names,
                ]
            )
        )
        untracked = subprocess.check_output(
            [
                *git,
                "ls-files",
                "--others",
                "--exclude-standard",
                "-z",
                "--",
                *names,
            ]
        )
        for name in sorted(filter(None, untracked.split(b"\0"))):
            digest.update(name + b"\0")
            digest.update((VENDOR / os.fsdecode(name)).read_bytes())
        return digest.hexdigest()
    except (OSError, ValueError, subprocess.CalledProcessError):
        # Source archives also work without Git metadata.
        digest = hashlib.sha256()
    inputs = [path for name in names for path in (VENDOR / name).rglob("*")]
    inputs.extend(path for name in names if (path := VENDOR / name).is_file())
    for path in sorted(inputs):
        if path.is_file() and path.suffix not in (".md", ".txt"):
            digest.update(str(path.relative_to(VENDOR)).encode())
            digest.update(path.read_bytes())
    return digest.hexdigest()


def recipe_revision(source: str, command: list[str | Path], tools: tuple[str | Path, ...]) -> str:
    identities = []
    for tool in tools:
        path = Path(shutil.which(str(tool)) or tool).resolve()
        stat = path.stat()
        identities.append((str(path), stat.st_size, stat.st_mtime_ns, stat.st_ctime_ns))
    return hashlib.sha256(
        json.dumps([source, list(map(str, command)), identities]).encode()
    ).hexdigest()


def prepare_compiler(
    target: str,
    toolchain: Path | None = None,
    *,
    lto: bool = False,
) -> tuple[Path, list[str]]:
    """Build the LLVM compiler and the game's Delphi-compatible runtime."""
    if target not in TARGETS:
        raise ValueError(f"Unsupported target: {target}")
    if target not in ("wasm", "android") and target != desktop_target():
        raise RuntimeError("Desktop builds require a host with the target OS.")
    if not (VENDOR / "compiler/pp.pas").is_file():
        raise FileNotFoundError(
            "Initialize dependencies with: git submodule update --init --recursive"
        )
    native_cpu = host_cpu()
    cpu = "wasm32" if target == "wasm" else "aarch64" if target == "android" else native_cpu
    system = {
        "linux": "linux",
        "macos": "darwin",
        "wasm": "wasip1threads",
        "android": "android",
    }[target]
    work = WORK / f"{cpu}-{system}"
    source = work / "source"
    if target == "wasm" and toolchain is None:
        raise RuntimeError("WebAssembly compilation requires Emscripten's LLVM tools.")
    if target == "android" and toolchain is None:
        raise RuntimeError("Android compilation requires the NDK LLVM tools.")
    # LLVM object emission is independent between units. Bound the worker
    # count so large units do not exhaust memory on hosts with many CPUs.
    jobs = f"-j{min(6, os.cpu_count() or 1)}"
    bootstrap_flags = (*llvm_options(), jobs)
    llvm_flags = (*llvm_options(toolchain / "clang"), jobs) if toolchain else bootstrap_flags
    if target in ("linux", "android"):
        llvm_flags += ("-Aclang-llvm",)
    if cpu == "x86_64":
        llvm_flags += ("-CpX86-64-V2", "-CfX86-64-V2")
    sdk = None
    if platform.system() == "Darwin":
        sdk = subprocess.check_output(["xcrun", "--show-sdk-path"], text=True).strip()
    make = shutil.which("gmake") or shutil.which("make")
    if make is None:
        raise FileNotFoundError("Install GNU Make to build the vendored compiler.")
    work.mkdir(parents=True, exist_ok=True)
    compiler_name = "ppcx64" if cpu == "x86_64" else "ppca64"
    cross_flags = []
    if target == "wasm":
        compiler_name = "ppcrosswasm32"
        # Build a host executable; compile the target runtime separately.
        cross_flags = [f"CPU_TARGET={cpu}", "CROSSINSTALL=1"]
        cross_flags.append("OS_TARGET=wasip1threads")
    elif target == "android" and native_cpu != cpu:
        compiler_name = "ppcrossa64"
        cross_flags = ["CPU_TARGET=aarch64", "CROSSINSTALL=1", "OS_TARGET=android"]
    compiler = source / "compiler" / compiler_name
    bootstrap = shutil.which(os.environ.get("FPC_BOOTSTRAP", "fpc"))
    if bootstrap is None:
        raise FileNotFoundError("Install FPC 3.2.2 to bootstrap the vendored compiler.")
    compiler_command = [
        make,
        "-C",
        source,
        "compiler_cycle",
        "NOWPOCYCLE=1",
        f"PP={bootstrap}",
        "OPT=-O2" + (f" -XR{sdk}" if sdk else ""),
        "LLVM=1",
        "OPTNEW=" + " ".join(bootstrap_flags),
        *cross_flags,
    ]
    revision = recipe_revision(source_revision(), compiler_command, (make, bootstrap, "clang"))
    stamp = BuildStamp(work / "compiler.stamp")
    if not stamp.matches(revision, compiler):
        with stamp.recording(revision):
            if source.exists():
                shutil.rmtree(source)
            shutil.copytree(VENDOR, source, ignore=shutil.ignore_patterns(".git"))
            run_step(work, "compiler", compiler_command)

    runtime = work / ("runtime-lto" if lto else "runtime")
    runtime_source = runtime / "src"
    units = runtime_source / "rtl/units" / f"{cpu}-{system}"
    options = [
        "-O2",
        "-OoNOFASTMATH",
        *llvm_flags,
        "-dCLASSESINLINE",
        "-dFPC_USE_SIMPLE_RANDOM",
        "-dFPC_USE_PC24_RANDOM",
        "-dFPC_USE_PC24_MATH",
    ]
    if target == "wasm":
        options += [
            "-Aclang-llvm",
            "-XP",
            f"-FD{toolchain}",
            "-dFPC_WASM_EMSCRIPTEN",
            "-dFPC_WASM_HOST_ALLOCATOR",
            "-dFPC_WASM_EMBEDDED_RUNTIME",
            "-dFPC_WASM_SEPARATE_WASI_IMPORTS",
        ]
        target_flags = [
            "CPU_TARGET=wasm32",
            "OS_TARGET=wasip1threads",
            "BINUTILSPREFIX=",
            f"CROSSBINDIR={toolchain}",
        ]
    elif target == "android":
        options += ["-Cg", "-XP", f"-FD{toolchain}"]
        target_flags = [
            "CPU_TARGET=aarch64",
            "OS_TARGET=android",
            "BINUTILSPREFIX=",
            f"CROSSBINDIR={toolchain}",
            "LOADERS=",
        ]
    elif target == "macos":
        options += ["-Aclang-llvm-darwin", f"-XR{sdk}"]
        target_flags = []
    else:
        target_flags = [f"CPU_TARGET={cpu}", "OS_TARGET=linux"]
    if lto:
        options.append("-Clflto")
    stamp = BuildStamp(runtime / "runtime.stamp")
    runtime_command = [
        make,
        "-C",
        runtime_source / "rtl",
        "all",
        *target_flags,
        f"FPC={compiler}",
        "OPT=" + " ".join(options),
    ]
    runtime_revision = recipe_revision(
        # The startup assembly below also depends on the Android API level.
        f"{revision}:{ANDROID_MIN_API}" if target == "android" else revision,
        runtime_command,
        (compiler, toolchain / "clang" if toolchain else "clang"),
    )
    runtime_outputs = [units / "classes.ppu"]
    if target == "android":
        runtime_outputs += [units / "prt0.o", units / "dllprt0.o"]
    if not stamp.matches(runtime_revision, *runtime_outputs):
        with stamp.recording(runtime_revision):
            if runtime_source.exists():
                shutil.rmtree(runtime_source)
            # Do not alter the native RTL used to bootstrap the compiler. Each
            # runtime profile starts from source and gets its own PPUs/objects.
            shutil.copytree(
                source / "rtl",
                runtime_source / "rtl",
                ignore=shutil.ignore_patterns("units"),
            )
            for name in ("compiler", "packages"):
                (runtime_source / name).symlink_to(source / name, target_is_directory=True)
            units.mkdir(parents=True, exist_ok=True)
            if target == "android":
                # NDK clang replaces GNU as for these tiny startup objects.
                for name in ("prt0", "dllprt0"):
                    run_step(
                        runtime,
                        name,
                        [
                            toolchain / "clang",
                            f"--target=aarch64-linux-android{ANDROID_MIN_API}",
                            "-x",
                            "assembler",
                            "-Wa,-defsym,CPU64=1",
                            "-c",
                            source / f"rtl/android/{name}.as",
                            "-o",
                            units / f"{name}.o",
                        ],
                    )
            run_step(runtime, "runtime", runtime_command)

    packages = VENDOR / "packages"
    paths = [
        units,
        packages / "rtl-objpas/src/inc",
        packages / "fcl-base/src",
        packages / "pthreads/src",
        packages / "fcl-process/src",
        *([packages / "rtl-unicode/src/inc"] if target in ("wasm", "android") else []),
    ]
    return compiler, [
        "-n", *llvm_flags, *(["-Clflto"] if lto else []),
        *(["-XLL"] if target in ("linux", "android") else []),
        *(["-Tandroid", "-Cg", "-XP", f"-FD{toolchain}"] if target == "android" else []),
        *(["-Twasip1threads", "-dFPC_WASM_EMSCRIPTEN", "-Aclang-llvm", "-XP", f"-FD{toolchain}"] if target == "wasm" else []),
        *(f"-Fu{path}" for path in paths),
        f"-Fi{packages}/fcl-process/src/unix",
    ]  # fmt: skip
