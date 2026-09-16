#!/usr/bin/env python3
"""Run the macOS or Windows game."""

import argparse
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--release", action="store_true", help="Run the optimized build.")
    parser.add_argument("--lto", action="store_true", help="Run the separate LTO build.")
    parser.add_argument(
        "--game-dir", type=Path, default=ROOT / "game", help="Game asset directory."
    )
    args, game_options = parser.parse_known_args()
    configuration = ("release" if args.release else "debug") + ("-lto" if args.lto else "")
    if os.name == "nt":
        binary = ROOT / ".local" / f"windows-{configuration}" / "Rangers/Rangers.exe"
    else:
        binary = ROOT / ".local" / configuration / "Space Rangers HD.app/Contents/MacOS/Rangers"
    if not binary.is_file():
        parser.error("Run ./tools/build.py first, with matching --release and --lto options.")
    game_directory = args.game_dir.expanduser().resolve()
    command = [str(binary), f"--game-dir={game_directory}", *game_options]
    try:
        if os.name == "nt":
            # Windows execv detaches the child from this console; wait so its output stays here.
            sys.exit(subprocess.call(command))
        os.execv(binary, command)
    except OSError as error:
        parser.exit(1, f"Cannot start the game: {error}\n")


if __name__ == "__main__":
    main()
