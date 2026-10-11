#!/usr/bin/env python3
"""Run the desktop or iOS simulator game, or serve the browser build."""

import argparse
import os
import subprocess
from pathlib import Path

from targets import ROOT, BuildConfig, add_build_arguments


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    add_build_arguments(parser)
    parser.add_argument("--port", type=int, default=8788, help="Browser server port.")
    parser.add_argument(
        "--simulator", help="iOS simulator name or UDID; defaults to the booted device."
    )
    parser.add_argument(
        "--game-dir",
        type=Path,
        help="Game asset directory; defaults to game/ on desktop/web. Imports assets on iOS.",
    )
    args, game_options = parser.parse_known_args()
    try:
        config = BuildConfig(
            args.target, args.release, args.lto, simulator_arch=args.simulator_arch
        )
    except ValueError as error:
        parser.error(str(error))
    if args.simulator and args.target != "ios-simulator":
        parser.error("--simulator requires --target=ios-simulator.")
    if args.target == "ios":
        parser.error("Sign and install the iOS app on your device; see BUILDING.md.")
    if args.target == "ios-simulator":
        if game_options:
            parser.error("The iOS launcher does not accept extra game options.")
        from ios import run_simulator

        directory = args.game_dir.expanduser().resolve() if args.game_dir else None
        try:
            run_simulator(config, directory, args.simulator)
        except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
            parser.exit(1, f"{error}\n")
        return
    if args.target == "android":
        parser.error(
            "Android runs from its launcher. Build with ./tools/build.py --target=android, "
            "then install the APK and import your game folder on the device. "
            "See BUILDING.md."
        )
    game_directory = (args.game_dir or ROOT / "game").expanduser().resolve()
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
