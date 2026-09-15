#!/usr/bin/env python3
"""Run the macOS game."""

import argparse
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--release", action="store_true", help="Run the optimized build.")
    parser.add_argument(
        "--game-dir", type=Path, default=ROOT / "game", help="Game asset directory."
    )
    args, game_options = parser.parse_known_args()
    configuration = "release" if args.release else "debug"
    binary = ROOT / ".local" / configuration / "Space Rangers HD.app/Contents/MacOS/Rangers"
    if not binary.is_file():
        parser.error("Run ./tools/build.py first, with the same --release option.")
    game_directory = args.game_dir.expanduser().resolve()
    command = [str(binary), f"--game-dir={game_directory}", *game_options]
    try:
        os.execv(binary, command)
    except OSError as error:
        parser.exit(1, f"Cannot start the game: {error}\n")


if __name__ == "__main__":
    main()
