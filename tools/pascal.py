"""FPC game/package compilation, including its unit invalidation rules."""

import json
from pathlib import Path

from build_support import (
    BuildStamp,
    command_signature,
    file_state,
    require_tool,
    run_step,
)
from targets import ROOT

PASCAL_FLAGS = ("-Mdelphi", "-FcUTF8")
PASCAL_INPUT_SUFFIXES = {
    ".pas",
    ".pp",
    ".inc",
    ".dpr",
    ".lpr",
    ".ppu",
    ".o",
    ".a",
    ".res",
    ".rc",
    ".s",
    ".as",
    ".ico",
    ".bmp",
    ".png",
    ".manifest",
}


def pascal_state(command: list[str | Path], dependencies: tuple[Path, ...]) -> str:
    roots = {Path(str(arg)[3:]) for arg in command if str(arg).startswith(("-Fu", "-Fi"))}
    sources = [Path(arg) for arg in command if str(arg).endswith((".pas", ".pp", ".dpr", ".lpr"))]
    roots.update(path.parent for path in sources)
    # Search paths include nested game directories. Visit each source tree once.
    roots = {path for path in roots if not any(parent in roots for parent in path.parents)}
    files = [
        path
        for root in roots
        for path in root.rglob("*")
        if path.suffix.lower() in PASCAL_INPUT_SUFFIXES and path.is_file()
    ]
    files.extend(sources)
    files.extend(dependencies)
    # Missing or externally replaced generated units also invalidate the cache.
    for arg in command:
        if str(arg).startswith("-FU"):
            files.extend(Path(str(arg)[3:]).glob("*.ppu"))
            files.extend(Path(str(arg)[3:]).glob("*.o"))
    return json.dumps(file_state(files))


def units_need_rebuild(previous: str, current: str, dependencies: tuple[Path, ...]) -> bool:
    """Catch changes that FPC's whole-second unit timestamps cannot distinguish.

    Linked libraries require another link, but do not invalidate Pascal units.
    Added/removed inputs and changed generated units require a full rebuild.
    """
    linked_files = set(map(str, dependencies))
    try:
        before = {e[0]: e[1:] for e in json.loads(previous) if e[0] not in linked_files}
        after = {e[0]: e[1:] for e in json.loads(current) if e[0] not in linked_files}
        if before.keys() != after.keys():
            return True
        for name, old in before.items():
            new = after[name]
            if old == new:
                continue
            if len(old) != 3 or len(new) != 3 or Path(name).suffix in (".ppu", ".o"):
                return True
            if old[1] // 1_000_000_000 == new[1] // 1_000_000_000:
                return True
    except (ValueError, TypeError, IndexError):
        # Missing or unreadable inventories cannot establish unit validity.
        return True
    return False


def compile_pascal(
    work: Path,
    command: list[str | Path],
    rebuild: bool,
    artifact: Path,
    dependencies: tuple[Path, ...] = (),
) -> bool:
    # FPC tracks unit/source dependencies, but not every change to compiler options.
    stamp = BuildStamp(work / "pascal-command.json")
    inputs = work / "pascal-inputs.json"
    # LLVM object emission runs a separate Clang executable. Its replacement
    # must invalidate the game/package objects as well as the compiler's RTL.
    directory = next((str(arg)[3:] for arg in reversed(command) if str(arg).startswith("-FD")), "")
    prefix = next((str(arg)[3:] for arg in reversed(command) if str(arg).startswith("-XP")), "")
    clang = require_tool(str(Path(directory) / (prefix + "clang")))
    signature = json.dumps([command_signature(command), file_state([clang])])
    state = pascal_state(command, dependencies)
    same_command = stamp.matches(signature)
    previous_inputs = inputs.read_text() if inputs.is_file() else ""
    same_inputs = previous_inputs == state
    if not rebuild and same_command and same_inputs and artifact.is_file():
        print("Pascal code is up to date.", flush=True)
        return False
    invalidate_units = not same_inputs and units_need_rebuild(previous_inputs, state, dependencies)
    if rebuild or not same_command or invalidate_units or ("-Ur" in command and not same_inputs):
        if "-Ur" in command:
            # Released dependencies ignore -B; invalidate their generated PPUs
            # before recompiling this package with its own language mode.
            for unit in work.glob("*.ppu"):
                unit.unlink()
        build_command = [command[0], "-B", *command[1:]]
    else:
        build_command = command
    # A failed build must not leave units compiled with a mixture of settings.
    with stamp.recording(signature):
        run_step(work, "pascal", build_command)
        inputs.write_text(pascal_state(command, dependencies))
    return True


def pascal_flags(release: bool, *platform_paths: Path) -> list[str]:
    search_paths = [
        *platform_paths,
        ROOT / "platform",
        ROOT / "vendor/fpc/packages/oggvorbis/src",
        ROOT / "vendor/fpc/packages/fcl-image/src",
        ROOT / "vendor/fpc/packages/pasjpeg/src",
        ROOT / "source",
        *sorted(path for path in (ROOT / "source").rglob("*") if path.is_dir()),
    ]
    return [
        *PASCAL_FLAGS,
        "-O4" if release else "-O2",
        *(["-OoAUTOINLINE"] if release else []),
        # -O4 enables field reordering and fast math; override it afterward.
        "-OoNOORDERFIELDS",
        "-OoNOFASTMATH",
        "-gl",
        f"-Fi{ROOT / 'source'}",
        *(f"-Fu{path}" for path in search_paths),
    ]


def build_paszlib(
    work: Path, compiler: Path, compiler_flags: list[str], rebuild: bool, *options: str
) -> Path:
    directory = work / "paszlib"
    directory.mkdir(parents=True, exist_ok=True)
    # This FPC package uses ObjFPC syntax. Build released units separately so
    # a game rebuild in Delphi mode does not recompile the package in that mode.
    compile_pascal(directory, [
        compiler, *compiler_flags, "-Mobjfpc", "-Ur", "-O2", *options,
        f"-FU{directory}", f"-FE{directory}",
        f"-Fu{ROOT / 'vendor/fpc/packages/hash/src'}",
        ROOT / "vendor/fpc/packages/paszlib/src/paszlib.pas",
    ], rebuild, directory / "paszlib.ppu")  # fmt: skip
    return directory
