"""Shared build options and output paths for the build and run commands."""

import argparse
import os
import platform
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TARGETS = ("linux", "macos", "win32", "win64", "wasm", "android", "ios", "ios-simulator", "switch")
# Installed Android identity, independent of the Java/JNI class namespace.
# A side-by-side test build may set another one; see package_android.
ANDROID_APPLICATION_ID = os.environ.get("ANDROID_APPLICATION_ID", "io.github.pakompom.spacerangershd")
# Package versions change for releases, not local rebuilds.
PACKAGE_VERSION = "0.1"
ANDROID_VERSION_CODE = 28
ANDROID_VERSION_NAME = PACKAGE_VERSION
ANDROID_MIN_API = 26
ANDROID_TARGET_API = 35
ANDROID_PAGE_SIZE = 16384
IOS_MIN_VERSION = "15.0"


def add_build_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--target", choices=TARGETS, default=desktop_target())
    parser.add_argument("--release", action="store_true", help="Select the optimized build.")
    parser.add_argument("--lto", action="store_true", help="Select LLVM link-time optimization.")
    parser.add_argument(
        "--simulator-arch",
        choices=("arm64", "x86_64"),
        help="Simulator CPU; defaults to the host CPU.",
    )


def desktop_target() -> str:
    system = platform.system()
    targets = {"Linux": "linux", "Darwin": "macos", "Windows": "win64"}
    if system not in targets:
        raise RuntimeError(f"Unsupported desktop host: {system}")
    return targets[system]


def windows_triple(cpu: str) -> str:
    return {"i386": "i686-w64-mingw32", "x86_64": "x86_64-w64-mingw32"}[cpu]


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
    simulator_arch: str | None = None

    def __post_init__(self) -> None:
        if self.target not in TARGETS:
            raise ValueError(f"Unsupported target: {self.target}")
        if self.target == "switch" and self.lto:
            raise ValueError("Switch currently links native ELF objects; omit --lto.")
        if self.simulator_arch is not None and (
            self.target != "ios-simulator" or self.simulator_arch not in ("arm64", "x86_64")
        ):
            raise ValueError(
                "--simulator-arch requires --target=ios-simulator and arm64 or x86_64."
            )

    @property
    def cpu(self) -> str:
        if self.target in ("win32", "win64"):
            return "i386" if self.target == "win32" else "x86_64"
        if self.target == "wasm":
            return "wasm32"
        if self.target in ("android", "ios", "switch"):
            return "aarch64"
        if self.simulator_arch:
            return "aarch64" if self.simulator_arch == "arm64" else "x86_64"
        return host_cpu()

    @property
    def ios_arch(self) -> str:
        return "arm64" if self.cpu == "aarch64" else self.cpu

    @property
    def profile(self) -> str:
        return ("release" if self.release else "debug") + ("-lto" if self.lto else "")

    @property
    def work(self) -> Path:
        directory = self.root / ".local"
        if self.target == "linux":
            directory /= f"linux-{self.cpu}"
        elif self.target in ("win32", "win64"):
            directory /= f"{self.target}-{self.cpu}"
        elif self.target == "wasm":
            directory /= "wasm"
        elif self.target == "android":
            directory /= "android-arm64"
        elif self.target == "switch":
            directory /= "switch-aarch64"
        elif self.target in ("ios", "ios-simulator"):
            directory /= f"{self.target}-{self.cpu}"
        return directory / self.profile

    @property
    def binary_directory(self) -> Path:
        if self.target == "macos":
            return self.work / "Space Rangers HD.app/Contents/MacOS"
        if self.target in ("ios", "ios-simulator"):
            return self.work / "SpaceRangersHD.app"
        return self.work / "bin"

    @property
    def units(self) -> Path:
        return self.work / "units"

    @property
    def artifact(self) -> Path:
        if self.target in ("win32", "win64"):
            return self.binary_directory / "Rangers.exe"
        if self.target == "macos":
            return self.work / "Space Rangers HD.app"
        if self.target == "wasm":
            return self.binary_directory / "index.html"
        if self.target == "android":
            return self.work / "Rangers.apk"
        if self.target == "switch":
            return self.binary_directory / "Rangers.nro"
        if self.target in ("ios", "ios-simulator"):
            return self.binary_directory
        return self.binary_directory / "Rangers"

    def create_directories(self) -> None:
        for directory in (self.binary_directory, self.units):
            directory.mkdir(parents=True, exist_ok=True)
