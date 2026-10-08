"""Shared build options and output paths for the build and run commands."""

import argparse
import platform
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TARGETS = ("linux", "macos", "wasm")


def add_build_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--target", choices=TARGETS, default=desktop_target())
    parser.add_argument("--release", action="store_true", help="Select the optimized build.")
    parser.add_argument("--lto", action="store_true", help="Select LLVM link-time optimization.")


def desktop_target() -> str:
    system = platform.system()
    if system not in ("Linux", "Darwin"):
        raise RuntimeError(f"Unsupported desktop host: {system}")
    return "linux" if system == "Linux" else "macos"


def host_cpu() -> str:
    """Use the host architecture for native desktop builds."""
    machine = platform.machine().lower()
    aliases = {"amd64": "x86_64", "arm64": "aarch64"}
    cpu = aliases.get(machine, machine)
    if cpu not in ("x86_64", "aarch64"):
        raise RuntimeError(f"Unsupported desktop architecture: {machine}")
    return cpu


@dataclass(frozen=True)
class BuildConfig:
    target: str
    release: bool = False
    lto: bool = False
    root: Path = ROOT

    def __post_init__(self):
        if self.target not in TARGETS:
            raise ValueError(f"Unsupported target: {self.target}")

    @property
    def profile(self) -> str:
        return ("release" if self.release else "debug") + ("-lto" if self.lto else "")

    @property
    def work(self) -> Path:
        directory = self.root / ".local"
        if self.target == "linux":
            directory /= f"linux-{host_cpu()}"
        elif self.target == "wasm":
            directory /= "wasm"
        return directory / self.profile

    @property
    def binary_directory(self) -> Path:
        if self.target == "macos":
            return self.work / "Space Rangers HD.app/Contents/MacOS"
        return self.work / "bin"

    @property
    def units(self) -> Path:
        return self.work / "units"

    @property
    def artifact(self) -> Path:
        if self.target == "macos":
            return self.work / "Space Rangers HD.app"
        if self.target == "wasm":
            return self.binary_directory / "index.html"
        return self.binary_directory / "Rangers"

    def create_directories(self) -> None:
        for directory in (self.binary_directory, self.units):
            directory.mkdir(parents=True, exist_ok=True)
