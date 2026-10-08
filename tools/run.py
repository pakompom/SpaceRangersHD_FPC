#!/usr/bin/env python3
"""Run the desktop game or serve the browser build."""

import argparse
import os
from pathlib import Path

from targets import ROOT, BuildConfig, add_build_arguments


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    add_build_arguments(parser)
    parser.add_argument("--port", type=int, default=8788, help="Browser server port.")
    parser.add_argument(
        "--game-dir", type=Path, default=ROOT / "game", help="Game asset directory."
    )
    args, game_options = parser.parse_known_args()
    config = BuildConfig(args.target, args.release, args.lto)
    game_directory = args.game_dir.expanduser().resolve()
    if not game_directory.is_dir():
        parser.error(f"Game asset directory does not exist: {game_directory}")
    if args.target == "wasm":
        if game_options:
            parser.error("The browser launcher does not accept command-line game options.")
        from serve import serve

        try:
            serve(config.binary_directory, game_directory, args.port)
        except OSError as error:
            parser.exit(1, f"{error}\n")
        return
    try:
        binary = config.binary_directory / "Rangers"
    except RuntimeError as error:
        parser.error(str(error))
    if not binary.is_file():
        parser.error(
            "Run ./tools/build.py first, with matching --target, --release and --lto options."
        )
    command = [str(binary), f"--game-dir={game_directory}", *game_options]
    try:
        os.execv(binary, command)
    except OSError as error:
        parser.exit(1, f"Cannot start the game: {error}\n")


if __name__ == "__main__":
    main()
