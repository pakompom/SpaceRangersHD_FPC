#!/usr/bin/env python3
"""Run the native desktop game."""

import argparse
import os
from pathlib import Path

from targets import desktop_binary, desktop_target

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target", choices=("linux", "macos"), default=desktop_target())
    parser.add_argument("--release", action="store_true", help="Run the optimized build.")
    parser.add_argument("--lto", action="store_true", help="Run the LTO build.")
    parser.add_argument(
        "--game-dir", type=Path, default=ROOT / "game", help="Game asset directory."
    )
    args, game_options = parser.parse_known_args()
    try:
        binary = desktop_binary(ROOT, args.target, args.release, args.lto)
    except RuntimeError as error:
        parser.error(str(error))
    if not binary.is_file():
        parser.error(
            "Run ./tools/build.py first, with matching --target, --release and --lto options."
        )
    game_directory = args.game_dir.expanduser().resolve()
    if not game_directory.is_dir():
        parser.error(f"Game asset directory does not exist: {game_directory}")
    command = [str(binary), f"--game-dir={game_directory}", *game_options]
    try:
        os.execv(binary, command)
    except OSError as error:
        parser.exit(1, f"Cannot start the game: {error}\n")


if __name__ == "__main__":
    main()
