"""Package CI outputs without game assets or signing material."""

import shutil
import subprocess
import sys
import tarfile
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))
from targets import BuildConfig, host_cpu


def git(*args: str) -> str:
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


def package(target: str) -> None:
    if target not in ("linux", "android"):
        raise ValueError(f"Unsupported release target: {target}")
    if target == "linux" and host_cpu() != "x86_64":
        raise ValueError("Linux releases require an x86_64 build host")
    config = BuildConfig(target, release=True, root=ROOT)
    platform = "linux-x86_64" if target == "linux" else "android-arm64"
    commit = git("rev-parse", "HEAD")
    name = f"SpaceRangersHD-{platform}-{commit[:12]}"
    destination = ROOT / "build/release"
    destination.mkdir(parents=True, exist_ok=True)
    info = destination / f"{name}-build.txt"
    info.write_text(
        f"Commit: {commit}\n"
        f"Subject: {git('show', '-s', '--format=%s', 'HEAD')}\n"
        f"Built: {datetime.now(timezone.utc).isoformat(timespec='seconds')}\n"
        f"Platform: {platform}\nProfile: release (-O4, no LTO)\n"
        f"FPC: {git('-C', 'vendor/fpc', 'rev-parse', 'HEAD')}\n"
        f"OKGF: {git('-C', 'vendor/okgf', 'rev-parse', 'HEAD')}\n"
    )
    if target == "android":
        shutil.copy2(config.artifact, destination / f"{name}.apk")
        symbols = ROOT / "build/android-symbols"
        if not any(symbols.glob("*/*.so")):
            raise FileNotFoundError("Android release symbols are missing")
        with tarfile.open(destination / f"{name}-symbols.tar.gz", "w:gz") as archive:
            archive.add(symbols, arcname="symbols")
        return

    staging = ROOT / "build/package" / name
    staging.mkdir(parents=True, exist_ok=True)
    for filename in ("Rangers", "libokgf.so"):
        shutil.copy2(config.binary_directory / filename, staging / filename)
    for filename in ("LICENSE", "NOTICE.md"):
        shutil.copy2(ROOT / filename, staging / filename)
    shutil.copy2(info, staging / "build.txt")
    licenses = staging / "licenses"
    licenses.mkdir(exist_ok=True)
    for source, filename in (
        ("licenses/spacerangershd-fpc-fixes.txt", "spacerangershd-fpc-fixes.txt"),
        ("vendor/okgf/LICENSE", "OKGF.txt"),
        ("vendor/okgf/vendor/softfloat/COPYING.txt", "SoftFloat.txt"),
        ("vendor/fpc/rtl/COPYING.FPC", "FPC.txt"),
        ("vendor/fpc/rtl/COPYING.txt", "FPC-LGPL.txt"),
        ("vendor/fpc/packages/paszlib/readme.txt", "paszlib.txt"),
        ("vendor/fpc/packages/pasjpeg/readme.txt", "pasjpeg.txt"),
    ):
        shutil.copy2(ROOT / source, licenses / filename)
    (staging / "README.txt").write_text(
        "Space Rangers HD — Free Pascal port\n\n"
        "Requires your own Space Rangers HD game data (not included).\n"
        "Built on Ubuntu 24.04; requires glibc 2.39+ and an x86-64-v2 CPU.\n"
        "Install runtime libraries on Ubuntu 24.04:\n"
        "sudo apt-get install libsdl2-2.0-0 libogg0 libvorbisfile3 libjpeg-turbo8 libpng16-16t64 libxvidcore4\n\n"
        "Keep Rangers and libokgf.so together, then run:\n"
        './Rangers --game-dir="/path/to/game"\n'
    )
    with tarfile.open(destination / f"{name}.tar.gz", "w:gz") as archive:
        archive.add(staging, arcname=name)


if __name__ == "__main__":
    package(sys.argv[1])
