"""Bootstrap the pinned FPC compiler and isolated platform runtimes."""

import hashlib
import json
import os
import platform
import re
import shutil
import subprocess
from pathlib import Path

from targets import desktop_target, host_cpu

ROOT = Path(__file__).resolve().parents[1]
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


def matches(path: Path, revision: str) -> bool:
    return path.is_file() and path.read_text() == revision


def prepare_compiler(
    target: str,
    run_step,
    toolchain: Path | None = None,
    *,
    lto: bool = False,
) -> tuple[Path, list[str]]:
    """Build the LLVM compiler and the game's Delphi-compatible runtime."""
    if target not in ("linux", "macos", "android"):
        raise ValueError(f"Unsupported target: {target}")
    if lto and target == "android":
        raise ValueError("LTO is not supported for Android builds.")
    if target != "android" and target != desktop_target():
        raise RuntimeError("Desktop builds require a host with the target OS.")
    if not (VENDOR / "compiler/pp.pas").is_file():
        raise FileNotFoundError(
            "Initialize dependencies with: git submodule update --init --recursive"
        )
    native_cpu = host_cpu()
    cpu = "aarch64" if target == "android" else native_cpu
    system = {
        "linux": "linux",
        "macos": "darwin",
        "android": "android",
    }[target]
    work = WORK / f"{cpu}-{system}"
    source = work / "source"
    if target == "android" and toolchain is None:
        raise RuntimeError("Android runtime compilation requires the NDK.")
    bootstrap_flags = llvm_options()
    llvm_flags = llvm_options(toolchain / "clang") if toolchain else bootstrap_flags
    if target == "linux":
        llvm_flags += ("-Aclang-llvm",)
    sdk = None
    if platform.system() == "Darwin":
        sdk = subprocess.check_output(["xcrun", "--show-sdk-path"], text=True).strip()
    make = shutil.which("gmake") or shutil.which("make")
    if make is None:
        raise FileNotFoundError("Install GNU Make to build the vendored compiler.")
    work.mkdir(parents=True, exist_ok=True)
    compiler_name = "ppcx64" if cpu == "x86_64" else "ppca64"
    cross_flags = []
    if cpu != native_cpu:
        compiler_name = "ppcrossa64"
        # Build a host executable; compile the target runtime separately.
        cross_flags = [f"CPU_TARGET={cpu}", "CROSSINSTALL=1"]
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
    stamp = work / "compiler.stamp"
    if not compiler.is_file() or not matches(stamp, revision):
        stamp.unlink(missing_ok=True)
        if source.exists():
            shutil.rmtree(source)
        shutil.copytree(VENDOR, source, ignore=shutil.ignore_patterns(".git"))
        run_step(work, "compiler", compiler_command)
        stamp.write_text(revision)

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
    if target == "android":
        options += ["-Cg", "-Aclang-llvm", "-XP"]
        target_flags = [
            "CPU_TARGET=aarch64",
            "OS_TARGET=android",
            "BINUTILSPREFIX=",
            f"CROSSBINDIR={toolchain}",
        ]
    elif target == "macos":
        options += ["-Aclang-llvm-darwin", f"-XR{sdk}"]
        target_flags = []
    else:
        target_flags = [f"CPU_TARGET={cpu}", "OS_TARGET=linux"]
    if lto:
        options.append("-Clflto")
    stamp = runtime / "runtime.stamp"
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
        revision,
        runtime_command,
        (compiler, toolchain / "clang" if toolchain else "clang"),
    )
    if not (units / "classes.ppu").is_file() or not matches(stamp, runtime_revision):
        runtime.mkdir(parents=True, exist_ok=True)
        stamp.unlink(missing_ok=True)
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
            for loader in ("prt0", "dllprt0"):
                run_step(runtime, loader, [
                    toolchain / "clang", "--target=aarch64-linux-android26", "-c",
                    "-x", "assembler", "-Wa,-defsym,CPU64=1",
                    runtime_source / f"rtl/android/{loader}.as", "-o", units / f"{loader}.o",
                ])  # fmt: skip
        run_step(runtime, "runtime", runtime_command)
        stamp.write_text(runtime_revision)

    packages = VENDOR / "packages"
    paths = [
        units,
        packages / "rtl-objpas/src/inc",
        packages / "fcl-base/src",
        packages / "pthreads/src",
        packages / "fcl-process/src",
    ]
    return compiler, [
        "-n", *llvm_flags, *(["-Clflto"] if lto else []),
        *(["-XLL"] if target == "linux" else []),
        *(f"-Fu{path}" for path in paths),
        f"-Fi{packages}/fcl-process/src/unix",
    ]  # fmt: skip
