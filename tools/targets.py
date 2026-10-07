"""Shared desktop target and artifact selection for build and run."""

import platform
from pathlib import Path


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


def desktop_directory(root: Path, target: str, release: bool, lto: bool = False) -> Path:
    configuration = "release" if release else "debug"
    if lto:
        configuration += "-lto"
    if target == "linux":
        return root / ".local" / f"linux-{host_cpu()}" / configuration
    return root / ".local" / configuration


def desktop_binary(root: Path, target: str, release: bool, lto: bool = False) -> Path:
    directory = desktop_directory(root, target, release, lto)
    if target == "linux":
        return directory / "bin/Rangers"
    return directory / "Space Rangers HD.app/Contents/MacOS/Rangers"
