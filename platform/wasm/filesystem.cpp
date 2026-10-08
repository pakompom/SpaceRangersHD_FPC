// Mount original package assets and persistent browser saves.
// FetchFS and OPFS block only the application's pthread; the browser UI stays
// on the main thread. No package conversion or game data embedding is needed.
#include "fpc_wasi.h"
#include <emscripten.h>
#include <emscripten/wasmfs.h>
#include <cerrno>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <stdexcept>
#include <string>
#include <unistd.h>

EM_JS_DEPS(fpc_filesystem, "$stringToNewUTF8");

namespace {
namespace fs = std::filesystem;
void mount(const char *path, backend_t backend) {
    if (!backend || wasmfs_create_directory(path, 0777, backend))
        throw std::runtime_error(std::string("Cannot mount ") + path);
}
void initialize_filesystem() {
    char *raw = static_cast<char *>(MAIN_THREAD_EM_ASM_PTR(
        { return stringToNewUTF8(new URL('assets', document.baseURI).href); }));
    std::string base(raw);
    free(raw);
    auto remote = wasmfs_create_fetch_backend(base.c_str(), 256 * 1024);
    mount("/game", remote);
    int fd = wasmfs_create_file("/game/manifest.txt", 0444, remote);
    if (fd < 0)
        throw std::runtime_error("Cannot create asset manifest entry");
    close(fd);
    std::ifstream manifest("/game/manifest.txt");
    if (!manifest)
        throw std::runtime_error("Cannot fetch asset manifest");
    size_t entries = 0;
    for (std::string name; std::getline(manifest, name);) {
        if (!name.empty() && name.back() == '\r')
            name.pop_back();
        fs::path relative(name);
        if (name.empty() || relative.is_absolute() || name.find('\0') != std::string::npos)
            throw std::runtime_error("Invalid asset manifest path");
        for (const auto &part : relative)
            if (part == "..")
                throw std::runtime_error("Invalid parent traversal in asset manifest");
        const auto path = fs::path("/game") / relative;
        fs::create_directories(path.parent_path());
        fd = wasmfs_create_file(path.c_str(), 0444, remote);
        if (fd < 0)
            throw std::runtime_error("Cannot index asset: " + name);
        close(fd);
        ++entries;
    }
    if (!entries || manifest.bad())
        throw std::runtime_error("Asset manifest is empty or unreadable");
    mount("/user", wasmfs_create_opfs_backend());
}
} // namespace

extern "C" int fpc_mount_filesystem(void) {
    try {
        initialize_filesystem();
        setenv("HOME", "/user", 1);
        return 0;
    } catch (const std::exception &error) {
        std::fprintf(stderr, "Filesystem initialization failed: %s\n", error.what());
        return EIO;
    }
}
