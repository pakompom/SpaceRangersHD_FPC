"""Build, package, and verify the ARM64 Android application."""

import hashlib
import json
import os
import platform
import re
import secrets
import shutil
import subprocess
import tarfile
import tempfile
import urllib.request
import zipfile
from pathlib import Path

from build_support import (
    build_okgf,
    configure_native,
    output,
    require_tool,
    run_step,
    sdl_source,
)
from compiler import prepare_compiler
from pascal import build_paszlib, compile_pascal, pascal_flags
from targets import (
    ANDROID_APPLICATION_ID,
    ANDROID_MIN_API,
    ANDROID_PAGE_SIZE,
    ANDROID_TARGET_API,
    ANDROID_VERSION_CODE,
    ANDROID_VERSION_NAME,
    ROOT,
    BuildConfig,
)

LIBRARIES = {
    "libSDL2.so": set(),
    "libokgf.so": set(),
    "libmain.so": {
        "SDL_main",
        "Java_io_github_pakompom_spacerangershd_GameActivity_nativeCancelTouch",
        "Java_io_github_pakompom_spacerangershd_GameActivity_nativeInputMode",
        "Java_io_github_pakompom_spacerangershd_GameActivity_nativeScroll",
    },
    "libRangers.so": {"sr_fpc_main"},
}
SYSTEM_LIBRARIES = {
    "libc.so",
    "libm.so",
    "libdl.so",
    "liblog.so",
    "libandroid.so",
    "libz.so",
    "libGLESv1_CM.so",
    "libGLESv2.so",
    "libEGL.so",
    "libOpenSLES.so",
    "libaaudio.so",
}
SOURCES = {
    "jpeg": (
        "https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/3.1.2/libjpeg-turbo-3.1.2.tar.gz",
        "8f0012234b464ce50890c490f18194f913a7b1f4e6a03d6644179fa0f867d0cf",
    ),
    "png": (
        "https://download.sourceforge.net/libpng/libpng-1.6.50.tar.gz",
        "708f4398f996325819936d447f982e0db90b6b8212b7507e7672ea232210949a",
    ),
    "ogg": (
        "https://downloads.xiph.org/releases/ogg/libogg-1.3.5.tar.xz",
        "c4d91be36fc8e54deae7575241e03f4211eb102afb3fc0775fbbc1b740016705",
    ),
    "vorbis": (
        "https://downloads.xiph.org/releases/vorbis/libvorbis-1.3.7.tar.xz",
        "b33cc4934322bcbf6efcbacf49e3ca01aadbea4114ec9589d1b1e9d20f72954b",
    ),
}


def newest_version(directory: Path) -> Path:
    choices = [
        path
        for path in directory.iterdir()
        if path.is_dir() and re.fullmatch(r"\d+(\.\d+)*", path.name)
    ]
    if not choices:
        raise FileNotFoundError(f"No installed Android tools in {directory}")
    return max(choices, key=lambda path: tuple(map(int, path.name.split("."))))


def android_sdk() -> Path:
    configured = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    default = "Library/Android/sdk" if platform.system() == "Darwin" else "Android/Sdk"
    return Path(configured).expanduser().resolve() if configured else Path.home() / default


def java_home() -> Path:
    configured = os.environ.get("JAVA_HOME")
    if configured:
        return Path(configured).expanduser().resolve()
    candidates = [
        Path("/opt/homebrew/opt/openjdk@21"),
        Path("/opt/homebrew/opt/openjdk"),
    ]
    if platform.system() == "Darwin":
        discovery = subprocess.run(
            ["/usr/libexec/java_home"], capture_output=True, text=True, check=False
        )
        if discovery.returncode == 0:
            candidates.append(Path(discovery.stdout.strip()))
    executable = shutil.which("javac")
    if executable:
        candidates.append(Path(executable).resolve().parents[1])
    for candidate in candidates:
        if (candidate / "bin/javac").is_file() and (candidate / "bin/keytool").is_file():
            return candidate
    raise FileNotFoundError("Set JAVA_HOME to a JDK 17 or newer installation")


def discover_ndk() -> Path:
    explicit = os.environ.get("ANDROID_NDK_HOME") or os.environ.get("ANDROID_NDK_ROOT")
    ndk = Path(explicit).expanduser() if explicit else newest_version(android_sdk() / "ndk")
    if not (ndk / "build/cmake/android.toolchain.cmake").is_file():
        raise FileNotFoundError(f"Invalid Android NDK: {ndk}")
    return ndk.resolve()


def ndk_toolchain(ndk: Path) -> Path:
    host = "darwin-x86_64" if platform.system() == "Darwin" else "linux-x86_64"
    toolchain = ndk / "toolchains/llvm/prebuilt" / host
    for name in ("clang", "ld.lld", "llvm-strip", "llvm-readelf"):
        require_tool(str(toolchain / "bin" / name))
    return toolchain


def dependency_source(name: str) -> Path:
    url, checksum = SOURCES[name]
    source = ROOT / ".local/android-sources" / f"{name}-{checksum[:12]}"
    if (source / ".complete").is_file():
        return source
    downloads = ROOT / ".local/downloads"
    downloads.mkdir(parents=True, exist_ok=True)
    archive = downloads / url.rsplit("/", 1)[1]
    if not archive.is_file():
        partial = archive.with_suffix(archive.suffix + ".partial")
        print(f"Downloading {url}", flush=True)
        urllib.request.urlretrieve(url, partial)
        partial.replace(archive)
    if hashlib.sha256(archive.read_bytes()).hexdigest() != checksum:
        raise RuntimeError(f"Dependency checksum mismatch: {archive}")
    source.mkdir(parents=True, exist_ok=True)
    with tarfile.open(archive) as contents:
        for member in contents.getmembers():
            parts = member.name.split("/", 1)
            if len(parts) == 2 and parts[1]:
                member.name = parts[1]
                contents.extract(member, source, filter="data")
    (source / ".complete").write_text(checksum)
    return source


def cmake_options(ndk: Path, prefix: Path) -> list[str]:
    return [
        f"-DCMAKE_TOOLCHAIN_FILE={ndk}/build/cmake/android.toolchain.cmake",
        "-DANDROID_ABI=arm64-v8a",
        f"-DANDROID_PLATFORM=android-{ANDROID_MIN_API}",
        "-DANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON",
        "-DCMAKE_POSITION_INDEPENDENT_CODE=ON",
        "-DCMAKE_C_FLAGS_RELEASE=-O2 -g -DNDEBUG",
        "-DCMAKE_CXX_FLAGS_RELEASE=-O3 -g -DNDEBUG",
        "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
        "-DBUILD_SHARED_LIBS=OFF",
        "-DBUILD_TESTING=OFF",
        f"-DCMAKE_INSTALL_PREFIX={prefix}",
        f"-DCMAKE_FIND_ROOT_PATH={prefix}",
        f"-DCMAKE_SHARED_LINKER_FLAGS=-Wl,-z,max-page-size={ANDROID_PAGE_SIZE} -Wl,-z,common-page-size={ANDROID_PAGE_SIZE} -Wl,--no-undefined",
    ]


def build_dependencies(config: BuildConfig, ndk: Path, rebuild: bool) -> Path:
    prefix = config.work / "dependencies/prefix"
    options = {
        "jpeg": ["-DENABLE_SHARED=OFF", "-DENABLE_STATIC=ON", "-DWITH_TURBOJPEG=OFF"],
        "png": [
            "-DPNG_SHARED=OFF",
            "-DPNG_STATIC=ON",
            "-DPNG_TESTS=OFF",
            "-DPNG_TOOLS=OFF",
        ],
        "ogg": [],
        "vorbis": [],
    }
    for name, extra in options.items():
        source = dependency_source(name)
        work = config.work / "dependencies" / name
        directory = work / "build"
        work.mkdir(parents=True, exist_ok=True)
        changed = configure_native(work, directory, [
            "cmake", "-S", source, "-B", directory, "-G", "Ninja",
            "-DCMAKE_BUILD_TYPE=Release",
            *cmake_options(ndk, prefix), *extra,
        ])  # fmt: skip
        run_step(work, name, [
            "cmake", "--build", directory, "--parallel", "6",
            *(["--clean-first"] if rebuild or changed else []),
        ])  # fmt: skip
        run_step(work, "install", ["cmake", "--install", directory])
    return prefix


def build_android(config: BuildConfig, rebuild: bool) -> Path:
    ndk = discover_ndk()
    toolchain = ndk_toolchain(ndk)
    config.create_directories()
    require_tool("cmake")
    require_tool("ninja")
    compiler, flags = prepare_compiler("android", toolchain / "bin", lto=config.lto)
    prefix = build_dependencies(config, ndk, rebuild)
    native = build_okgf(
        config.work,
        config.release,
        *cmake_options(ndk, prefix),
        rebuild=rebuild,
        android=True,
    )
    paszlib = build_paszlib(config.work, compiler, flags, rebuild)
    syslibs = toolchain / "sysroot/usr/lib/aarch64-linux-android"
    # NDK r23+ supplies compiler-rt and libunwind instead of libgcc.
    builtins = Path(
        output(
            str(toolchain / "bin/clang"),
            f"--target=aarch64-linux-android{ANDROID_MIN_API}",
            "--print-libgcc-file-name",
        )
    )
    unwind = builtins.parent / "aarch64/libunwind.a"
    if not unwind.is_file():
        raise FileNotFoundError(f"NDK ARM64 unwinder is missing: {unwind}")
    libraries = [
        native / "libokgf.so",
        native / "libSDL2.so",
        builtins,
        unwind,
        toolchain / "bin/ld.lld",
    ]
    libraries.extend(prefix.glob("lib/*.a"))
    # The unversioned sysroot directory contains static libc/m/dl.
    # Android shared libraries must use the API-specific bionic stubs.
    compile_pascal(config.work, [
        compiler, *flags, *pascal_flags(config.release, paszlib, ROOT / "platform/android"),
        f"-FU{config.units}", f"-FE{config.binary_directory}", f"-Fl{native}",
        f"-Fl{prefix / 'lib'}", f"-Fl{syslibs / str(ANDROID_MIN_API)}",
        f"-Fl{unwind.parent}", f"-Fl{builtins.parent}",
        f'-k"-L{native}"', "-k-lokgf", f'-k"{builtins}"',
        "-k-z", f"-kmax-page-size={ANDROID_PAGE_SIZE}", "-k-z", f"-kcommon-page-size={ANDROID_PAGE_SIZE}",
        "-k--no-undefined", ROOT / "source/Rangers.dpr",
    ], rebuild, config.binary_directory / "libRangers.so", tuple(libraries))  # fmt: skip
    return package_android(config, native, ndk)


def verify_library(library: Path, readelf: Path) -> None:
    """Check the library going into the APK using the NDK's ELF reader."""
    info = json.loads(
        output(
            str(readelf),
            "--elf-output-style=JSON",
            "-h",
            "-l",
            "--dyn-syms",
            "--needed-libs",
            str(library),
        )
    )[0]
    summary, header = info["FileSummary"], info["ElfHeader"]
    if summary["Format"] != "elf64-littleaarch64" or not header["Type"].startswith("SharedObject"):
        raise RuntimeError(f"{library.name}: expected an ARM64 Android shared library")
    segments = [entry["ProgramHeader"] for entry in info["ProgramHeaders"]]
    loads = [entry for entry in segments if entry["Type"]["Name"] == "PT_LOAD"]
    if not loads or any(
        entry["Alignment"] < ANDROID_PAGE_SIZE
        or (entry["Offset"] - entry["VirtualAddress"]) % ANDROID_PAGE_SIZE
        for entry in loads
    ):
        raise RuntimeError(
            f"{library.name}: LOAD segments need {ANDROID_PAGE_SIZE // 1024} KiB alignment"
        )
    for entry in segments:
        if (
            entry["Type"]["Name"] == "PT_GNU_RELRO"
            and (entry["VirtualAddress"] + entry["MemSize"]) % ANDROID_PAGE_SIZE
        ):
            raise RuntimeError(
                f"{library.name}: RELRO protection ends within a {ANDROID_PAGE_SIZE // 1024} KiB page"
            )
    if library.name == "libRangers.so" and not any(
        entry["Type"]["Name"] == "PT_GNU_EH_FRAME" and entry["MemSize"] for entry in segments
    ):
        raise RuntimeError("libRangers.so needs PT_GNU_EH_FRAME for exception handling")
    needed = set(info["NeededLibraries"])
    missing = needed - LIBRARIES.keys() - SYSTEM_LIBRARIES
    if missing:
        raise RuntimeError(f"{library.name}: unbundled dependencies: {sorted(missing)}")
    if "libc.so" not in needed or summary["LoadName"] != library.name:
        raise RuntimeError(f"{library.name}: requires its own SONAME and Android's shared libc")
    exports = {
        symbol["Name"]["Name"]
        for item in info["DynamicSymbols"]
        if (symbol := item["Symbol"])["Section"]["Value"]
        and symbol["Binding"]["Value"] in (1, 2)
        and symbol["Other"]["Value"] & 3 in (0, 3)
    }
    if missing_exports := LIBRARIES[library.name] - exports:
        raise RuntimeError(f"{library.name}: missing exports: {sorted(missing_exports)}")
    # LLVM 19 prints the dynamic table as text even with JSON output selected.
    dynamic = output(str(readelf), "-d", str(library))
    if re.search(r"\b(?:TEXTREL|RPATH|RUNPATH)\b", dynamic):
        raise RuntimeError(f"{library.name}: unexpected text relocations or runtime search path")
    print(
        f"Verified {library.name}: ARM64, {ANDROID_PAGE_SIZE // 1024} KiB pages, exports and dependencies.",
        flush=True,
    )


def package_android(config: BuildConfig, native: Path, ndk: Path) -> Path:
    work = config.work / "package"
    work.mkdir(parents=True, exist_ok=True)
    sdk = android_sdk()
    android = sdk / f"platforms/android-{ANDROID_TARGET_API}/android.jar"
    build_tools = newest_version(sdk / "build-tools")
    java = java_home()
    # d8/apksigner launch Java themselves; keep them on the same JDK as javac.
    os.environ["JAVA_HOME"] = str(java)
    llvm = ndk_toolchain(ndk) / "bin"
    for required in [
        android,
        java / "bin/javac",
        java / "bin/keytool",
        llvm / "llvm-strip",
        *(build_tools / name for name in ("d8", "aapt2", "zipalign", "apksigner")),
    ]:
        if not required.is_file():
            raise FileNotFoundError(f"Missing Android package input: {required}")
    sdl = sdl_source(native)
    app = config.root / "platform/android"
    sources = sorted(app.glob("java/**/*.java")) + sorted(
        (sdl / "android-project/app/src/main/java").rglob("*.java")
    )
    if not sources:
        raise FileNotFoundError("No Android Java sources found")
    # Temporary class/DEX directories prevent removed classes surviving updates.
    with tempfile.TemporaryDirectory(prefix="java-", dir=work) as temporary:
        classes = Path(temporary) / "classes"
        dex = Path(temporary) / "dex"
        generated = Path(temporary) / "generated"
        resources = Path(temporary) / "resources.zip"
        classes.mkdir()
        dex.mkdir()
        generated.mkdir()
        run_step(work, "resources", [
            build_tools / "aapt2", "compile", "--dir", app / "res", "-o", resources,
        ])  # fmt: skip
        unsigned = work / "unsigned.apk"
        run_step(work, "apk", [
            build_tools / "aapt2", "link", "-I", android,
            "--manifest", app / "AndroidManifest.xml", "--version-code", str(ANDROID_VERSION_CODE),
            "--rename-manifest-package", ANDROID_APPLICATION_ID,
            "--min-sdk-version", str(ANDROID_MIN_API), "--target-sdk-version", str(ANDROID_TARGET_API),
            *([] if config.release else ["--debug-mode"]),
            "--version-name", ANDROID_VERSION_NAME, "--java", generated, "-o", unsigned, resources,
        ])  # fmt: skip
        run_step(work, "java", [
            java / "bin/javac", "-encoding", "UTF-8", "--release", "8",
            "-classpath", android, "-d", classes, *sources, *sorted(generated.rglob("*.java")),
        ])  # fmt: skip
        run_step(work, "dex", [
            build_tools / "d8", "--lib", android, "--min-api", str(ANDROID_MIN_API),
            "--output", dex, *sorted(classes.rglob("*.class")),
        ])  # fmt: skip
        libraries = [
            (config.binary_directory if name == "libRangers.so" else native) / name
            for name in LIBRARIES
        ]
        licenses = {
            "port.txt": config.root / "LICENSE",
            "attribution.md": config.root / "NOTICE.md",
            "SDL2.txt": sdl / "LICENSE.txt",
            "OKGF.txt": config.root / "vendor/okgf/LICENSE",
            "SoftFloat.txt": config.root / "vendor/okgf/vendor/softfloat/COPYING.txt",
            "FPC.txt": config.root / "vendor/fpc/rtl/COPYING.FPC",
            "FPC-LGPL.txt": config.root / "vendor/fpc/rtl/COPYING.txt",
            "paszlib.txt": config.root / "vendor/fpc/packages/paszlib/readme.txt",
            "spacerangershd-fpc-fixes.txt": config.root / "licenses/spacerangershd-fpc-fixes.txt",
            "NDK.txt": ndk / "NOTICE",
        }
        for name, filename in (
            ("jpeg", "LICENSE.md"),
            ("png", "LICENSE"),
            ("ogg", "COPYING"),
            ("vorbis", "COPYING"),
        ):
            licenses[f"{name}.txt"] = dependency_source(name) / filename
        licenses["jpeg-IJG.txt"] = dependency_source("jpeg") / "README.ijg"
        with zipfile.ZipFile(unsigned, "a", compression=zipfile.ZIP_DEFLATED) as archive:
            for item in sorted(dex.glob("*.dex")):
                archive.write(item, item.name)
            for library in libraries:
                packaged = work / library.name
                shutil.copy2(library, packaged)
                if config.release:
                    run_step(
                        work,
                        f"strip-{library.stem}",
                        [llvm / "llvm-strip", "--strip-unneeded", packaged],
                    )
                verify_library(packaged, llvm / "llvm-readelf")
                archive.write(packaged, "lib/arm64-v8a/" + library.name)
            for name, path in licenses.items():
                archive.write(path, "assets/licenses/" + name)
    aligned = work / "aligned.apk"
    run_step(
        work,
        "align",
        [
            build_tools / "zipalign",
            "-f",
            "-P",
            str(ANDROID_PAGE_SIZE // 1024),
            "4",
            unsigned,
            aligned,
        ],
    )
    # Share the local key between debug/release profiles. Updates must use the
    # same certificate; never silently replace a key whose password is missing.
    signing = config.root / "build/android-signing"
    signing.mkdir(parents=True, mode=0o700, exist_ok=True)
    signing.chmod(0o700)
    key, password = signing / "srhd.p12", signing / "password"
    if key.exists() and not password.exists():
        raise FileNotFoundError(f"Signing password is missing; restore {password}")
    if not key.exists():
        if not password.exists():
            with password.open("x") as stream:
                stream.write(secrets.token_urlsafe(32))
            password.chmod(0o600)
        run_step(work, "signing-key", [
            java / "bin/keytool", "-genkeypair", "-keystore", key, "-storetype", "PKCS12",
            "-alias", "srhd", "-storepass:file", password, "-keyalg", "RSA", "-keysize", "3072",
            "-validity", "10000", "-dname", "CN=Space Rangers FPC Android Local Builds",
        ])  # fmt: skip
        key.chmod(0o600)
    signed = work / "signed.apk"
    run_step(work, "sign", [
        build_tools / "apksigner", "sign", "--ks", key, "--ks-pass", "file:" + str(password),
        "--v4-signing-enabled", "false", "--out", signed, aligned,
    ])  # fmt: skip
    run_step(
        work,
        "verify-signature",
        [build_tools / "apksigner", "verify", "--verbose", signed],
    )
    run_step(
        work,
        "verify-alignment",
        [
            build_tools / "zipalign",
            "-c",
            "-P",
            str(ANDROID_PAGE_SIZE // 1024),
            "4",
            signed,
        ],
    )
    badging = output(str(build_tools / "aapt2"), "dump", "badging", str(signed))
    if not badging.startswith(f"package: name='{ANDROID_APPLICATION_ID}' "):
        raise RuntimeError("APK application ID does not match ANDROID_APPLICATION_ID")
    if ("application-debuggable" in badging.splitlines()) != (not config.release):
        raise RuntimeError("APK debugging flag does not match the build profile")
    with zipfile.ZipFile(signed) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)):
            raise RuntimeError("APK contains duplicate entries")
        expected = {f"lib/arm64-v8a/{name}" for name in LIBRARIES}
        if {name for name in names if name.startswith("lib/")} != expected:
            raise RuntimeError("APK does not contain exactly the required ARM64 libraries")
        if not {"classes.dex", "AndroidManifest.xml", "resources.arsc"} <= set(names):
            raise RuntimeError("APK is missing its application metadata")
    if config.release:
        # Build IDs match crash reports even when APK versions stay unchanged.
        symbols = config.root / "build/android-symbols"
        for library in libraries:
            notes = output(str(llvm / "llvm-readelf"), "--notes", str(library))
            build_id = re.search(r"Build ID: ([0-9a-f]+)", notes)
            if build_id is None:
                raise RuntimeError(f"{library.name}: missing ELF build ID")
            directory = symbols / build_id[1]
            directory.mkdir(parents=True, exist_ok=True)
            temporary = directory / (library.name + ".tmp")
            shutil.copy2(library, temporary)
            temporary.replace(directory / library.name)
        print(f"Saved release symbols: {symbols}", flush=True)
    # Keep the old APK until all checks and archival have succeeded.
    signed.replace(config.artifact)
    return config.artifact
