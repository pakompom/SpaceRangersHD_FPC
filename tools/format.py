#!/usr/bin/env python3
"""Format Pascal, C, Java, Python, CMake, and XML source."""

import argparse
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIRECTORIES = ("source", "platform", "native", "tools")
FORMATTERS = ("pasfmt", "clang-format", "ruff", "cmake-format", "xmllint")


def source_files(*suffixes: str) -> list[str]:
    return sorted(
        str(path.relative_to(ROOT))
        for directory in SOURCE_DIRECTORIES
        for path in (ROOT / directory).rglob("*")
        if path.is_file() and path.suffix in suffixes
    )


def format_xml(check: bool) -> None:
    for name in source_files(".xml"):
        formatted = subprocess.check_output(["xmllint", "--format", name], cwd=ROOT)
        path = ROOT / name
        if check:
            if formatted != path.read_bytes():
                raise RuntimeError(f"Needs formatting: {name}")
        else:
            path.write_bytes(formatted)


def format_sources(check: bool) -> None:
    commands = [
        ["pasfmt", "--mode", "check" if check else "files", *source_files(".pas", ".dpr", ".lpr")],
        [
            "clang-format",
            *(["--dry-run", "--Werror"] if check else ["-i"]),
            *source_files(".c", ".h", ".java"),
        ],
        [
            "ruff",
            "format",
            "--line-length",
            "100",
            *(["--check"] if check else []),
            *source_files(".py"),
        ],
        [
            "cmake-format",
            "--line-width",
            "100",
            "--check" if check else "-i",
            "native/CMakeLists.txt",
        ],
    ]
    for command in commands:
        subprocess.run(command, cwd=ROOT, check=True)
    format_xml(check)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check", action="store_true", help="Check formatting without changing files."
    )
    args = parser.parse_args()
    missing = [tool for tool in FORMATTERS if shutil.which(tool) is None]
    if missing:
        parser.error("Install these formatters and add them to PATH: " + ", ".join(missing))
    try:
        format_sources(args.check)
    except subprocess.CalledProcessError as error:
        parser.exit(error.returncode, f"{error.cmd[0]} failed.\n")
    except (OSError, RuntimeError) as error:
        parser.exit(1, f"{error}\n")


if __name__ == "__main__":
    main()
