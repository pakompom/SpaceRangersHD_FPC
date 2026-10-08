#!/usr/bin/env python3
"""Format project sources with the formatters needed by the files present."""

import argparse
import shutil
import subprocess

from targets import ROOT

SOURCE_DIRECTORIES = ("source", "platform", "native", "tools", "tests")


def source_files(*suffixes: str) -> list[str]:
    return sorted(
        str(path.relative_to(ROOT))
        for directory in SOURCE_DIRECTORIES
        for path in (ROOT / directory).rglob("*")
        if path.is_file() and path.suffix in suffixes
    )


def format_xml(files: list[str], check: bool) -> None:
    for name in files:
        formatted = subprocess.check_output(["xmllint", "--format", name], cwd=ROOT)
        path = ROOT / name
        if check:
            if formatted != path.read_bytes():
                raise RuntimeError(f"Needs formatting: {name}")
        else:
            path.write_bytes(formatted)


def format_sources(check: bool) -> None:
    jobs = [
        (["pasfmt", "--mode", "check" if check else "files"], source_files(".pas", ".dpr", ".lpr")),
        (
            ["clang-format", *(["--dry-run", "--Werror"] if check else ["-i"])],
            source_files(".c", ".cpp", ".h", ".java"),
        ),
        (
            ["ruff", "format", "--line-length", "100", *(["--check"] if check else [])],
            source_files(".py"),
        ),
        (
            ["cmake-format", "--line-width", "100", "--check" if check else "-i"],
            ["native/CMakeLists.txt"],
        ),
    ]
    xml = source_files(".xml")
    required = [command[0] for command, files in jobs if files]
    if xml:
        required.append("xmllint")
    missing = [tool for tool in required if shutil.which(tool) is None]
    if missing:
        raise RuntimeError("Install these formatters and add them to PATH: " + ", ".join(missing))
    for command, files in jobs:
        # Some formatters read stdin when no filenames are supplied.
        if files:
            subprocess.run([*command, *files], cwd=ROOT, check=True)
    format_xml(xml, check)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check", action="store_true", help="Check formatting without changing files."
    )
    args = parser.parse_args()
    try:
        format_sources(args.check)
    except subprocess.CalledProcessError as error:
        parser.exit(error.returncode, f"{error.cmd[0]} failed.\n")
    except (OSError, RuntimeError) as error:
        parser.exit(1, f"{error}\n")


if __name__ == "__main__":
    main()
