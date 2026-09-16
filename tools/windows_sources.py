#!/usr/bin/env python3
"""Stage the Pascal sources for Windows with the Win32 shim units renamed.

On Windows the Free Pascal RTL ships real `windows` and `messages` units, and
SysUtils is compiled against the real `windows`, so the port's SDL-backed shims
cannot keep those names there. Rather than renaming them in the repository, which
would touch nearly every unit, the Windows build compiles a staged copy that
rewrites unit headers, uses clauses and unit-qualified references
(`Windows.CopyMemory`) while leaving strings and comments alone. Line numbers do
not change, so compiler messages and backtraces map back to the originals.
"""

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
# Shim unit -> replacement. `qualified` also rewrites `Unit.Member` references;
# Messages is empty, so any `Messages.` in game code is a variable, not the unit.
RENAMES = {
    "windows": ("SRWindows", True),
    "messages": ("SRMessages", False),
}
SUFFIXES = (".pas", ".dpr", ".lpr", ".inc", ".pp")
IDENTIFIER = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")


def skip_trivia(text: str, index: int) -> int:
    """Skip whitespace and comments; return the next significant index."""
    while index < len(text):
        char = text[index]
        if char.isspace():
            index += 1
        elif text.startswith("//", index):
            end = text.find("\n", index)
            index = len(text) if end < 0 else end + 1
        elif char == "{":
            end = text.find("}", index)
            index = len(text) if end < 0 else end + 1
        elif text.startswith("(*", index):
            end = text.find("*)", index + 2)
            index = len(text) if end < 0 else end + 2
        else:
            break
    return index


def rewrite(text: str) -> tuple[str, int]:
    output: list[str] = []
    index = 0
    in_uses = False
    previous = ""  # previous significant identifier, lowercased
    count = 0
    while index < len(text):
        start = skip_trivia(text, index)
        output.append(text[index:start])
        index = start
        if index >= len(text):
            break
        char = text[index]
        if char == "'":
            end = index + 1
            while end < len(text):
                if text[end] == "'":
                    if end + 1 < len(text) and text[end + 1] == "'":
                        end += 2
                        continue
                    break
                end += 1
            output.append(text[index : end + 1])
            index = end + 1
            continue
        match = IDENTIFIER.match(text, index)
        if match is None:
            if char == ";":
                in_uses = False
            output.append(char)
            index += 1
            previous = ""
            continue
        word = match.group(0)
        lower = word.lower()
        index = match.end()
        replacement = word
        if lower in RENAMES:
            new_name, qualified = RENAMES[lower]
            after = skip_trivia(text, index)
            is_member = after < len(text) and text[after] == "." and text[after : after + 2] != ".."
            if in_uses or previous == "unit" or (qualified and is_member and previous != "."):
                replacement = new_name
                count += 1
        if lower == "uses":
            in_uses = True
        output.append(replacement)
        previous = lower
    return "".join(output), count


def staged_path(relative: Path) -> Path:
    """Shim units keep their unit header in step with their new file name."""
    if relative.parent == Path("platform") and relative.stem.lower() in RENAMES:
        return relative.with_name(RENAMES[relative.stem.lower()][0] + relative.suffix)
    return relative


def source_files() -> list[Path]:
    return sorted(
        path
        for directory in (ROOT / "source", ROOT / "platform")
        for path in directory.rglob("*")
        if path.is_file()
        and path.suffix.lower() in SUFFIXES
        # Android's platform overrides are never on the Windows unit path.
        and ROOT / "platform/android" not in path.parents
    )


def stage_windows_sources(destination: Path) -> Path:
    """Mirror the Pascal sources into `destination` with the shims renamed.

    Only files whose staged content changes are rewritten, so FPC's timestamp checks
    keep incremental builds incremental. Files no longer in the tree are removed.
    """
    staged = set()
    for path in source_files():
        text = path.read_bytes().decode("latin-1")  # Latin-1 round-trips every byte.
        data = rewrite(text)[0].encode("latin-1")
        target = destination / staged_path(path.relative_to(ROOT))
        staged.add(target)
        if not target.is_file() or target.read_bytes() != data:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
    if destination.is_dir():
        for path in destination.rglob("*"):
            if path.is_file() and path not in staged:
                path.unlink()
    return destination


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "destination",
        nargs="?",
        type=Path,
        default=ROOT / ".local/windows-sources",
        help="Directory to stage the renamed sources in.",
    )
    args = parser.parse_args()
    print(f"Staged: {stage_windows_sources(args.destination.resolve())}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
