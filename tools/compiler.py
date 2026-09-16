"""Bootstrap the FPC submodule's LLVM compiler and platform runtimes."""

import hashlib
import os
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VENDOR = ROOT / "vendor/fpc"
WORK = ROOT / ".local/fpc"
SOURCE = WORK / "source"
LLVM_FLAGS = ("-Clv17.0",)


def source_revision() -> str:
    """Invalidate generated compilers when their source or build recipe changes."""
    digest = hashlib.sha256(Path(__file__).read_bytes())
    for path in sorted(VENDOR.rglob("*")):
        # A submodule's .git file describes its checkout, not compiler inputs.
        if ".git" in path.relative_to(VENDOR).parts:
            continue
        if path.is_file() and path.suffix not in (".md", ".txt"):
            digest.update(str(path.relative_to(VENDOR)).encode())
            digest.update(path.read_bytes())
    return digest.hexdigest()


def matches(path: Path, revision: str) -> bool:
    return path.is_file() and path.read_text() == revision


def prepare_compiler(
    target: str, run_step, toolchain: Path | None = None, *, lto: bool = False
) -> tuple[Path, list[str]]:
    """Use one host compiler with separate native and LTO runtimes."""
    if lto and target != "macos":
        raise ValueError("LTO is currently supported only for macOS builds.")
    if not (VENDOR / "compiler/pp.pas").is_file():
        raise FileNotFoundError(
            "Initialize dependencies with: git submodule update --init --recursive"
        )
    revision = source_revision()
    WORK.mkdir(parents=True, exist_ok=True)
    compiler = SOURCE / "compiler/ppca64"
    stamp = WORK / "compiler.stamp"
    if not compiler.is_file() or not matches(stamp, revision):
        bootstrap = shutil.which(os.environ.get("FPC_BOOTSTRAP", "fpc"))
        if bootstrap is None:
            raise FileNotFoundError("Install FPC 3.2.2 to bootstrap the vendored compiler.")
        sdk = subprocess.check_output(["xcrun", "--show-sdk-path"], text=True).strip()
        stamp.unlink(missing_ok=True)
        if SOURCE.exists():
            shutil.rmtree(SOURCE)
        shutil.copytree(VENDOR, SOURCE, ignore=shutil.ignore_patterns(".git"))
        run_step(WORK, "compiler", [
            "gmake", "-C", SOURCE, "compiler_cycle", "LLVM=1", "NOWPOCYCLE=1",
            f"PP={bootstrap}", f"OPT=-O2 -XR{sdk}", "OPTNEW=-Clv17.0",
        ])  # fmt: skip
        stamp.write_text(revision)

    system = "android" if target == "android" else "darwin"
    sdk = subprocess.check_output(["xcrun", "--show-sdk-path"], text=True).strip()
    runtime = WORK / "runtime" / (f"aarch64-{system}" + ("-lto" if lto else ""))
    runtime_source = runtime / "src"
    units = runtime_source / "rtl/units" / f"aarch64-{system}"
    options = ["-O2", *LLVM_FLAGS, "-dCLASSESINLINE"]
    if target == "android":
        if toolchain is None:
            raise RuntimeError("Android runtime compilation requires the NDK.")
        options += ["-Cg", "-Aclang-llvm", "-XP"]
        target_flags = [
            "CPU_TARGET=aarch64",
            "OS_TARGET=android",
            "BINUTILSPREFIX=",
            f"CROSSBINDIR={toolchain}",
        ]
    else:
        options += ["-Aclang-llvm-darwin", f"-XR{sdk}"]
        target_flags = []
    if lto:
        options.append("-Clflto")
    stamp = runtime / "runtime.stamp"
    runtime_revision = revision + repr((options, target_flags))
    if not (units / "classes.ppu").is_file() or not matches(stamp, runtime_revision):
        runtime.mkdir(parents=True, exist_ok=True)
        stamp.unlink(missing_ok=True)
        if runtime_source.exists():
            shutil.rmtree(runtime_source)
        # Do not alter the native RTL used to bootstrap the compiler. Each
        # runtime profile starts from source and gets its own PPUs/objects.
        shutil.copytree(
            SOURCE / "rtl", runtime_source / "rtl", ignore=shutil.ignore_patterns("units")
        )
        for name in ("compiler", "packages"):
            (runtime_source / name).symlink_to(SOURCE / name, target_is_directory=True)
        units.mkdir(parents=True, exist_ok=True)
        if target == "android":
            for loader in ("prt0", "dllprt0"):
                run_step(runtime, loader, [
                    toolchain / "clang", "--target=aarch64-linux-android26", "-c",
                    "-x", "assembler", "-Wa,-defsym,CPU64=1",
                    runtime_source / f"rtl/android/{loader}.as", "-o", units / f"{loader}.o",
                ])  # fmt: skip
        run_step(runtime, "runtime", [
            "gmake", "-C", runtime_source / "rtl", "all", *target_flags,
            f"FPC={compiler}", "OPT=" + " ".join(options),
        ])  # fmt: skip
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
        "-n", *LLVM_FLAGS, *(["-Clflto"] if lto else []), *(f"-Fu{path}" for path in paths),
        f"-Fi{packages}/fcl-process/src/unix",
    ]  # fmt: skip
