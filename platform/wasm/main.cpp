#include "fpc_wasi.h"
#include <algorithm>
#include <cstdint>
#include <emscripten.h>
#include <emscripten/heap.h>
#include <malloc.h>
#include <unistd.h>

extern "C" void fpc_wasm_start(void);

// Emscripten starts this on the application's pthread. Its main browser thread
// remains available for WebGL, audio, input and synchronous filesystem proxies.
int main(int argc, char **argv) {
    if (fpc_mount_filesystem() || fpc_wasi_initialize(argc, argv)) {
        fpc_browser_exit(1);
        return 1;
    }
    fpc_wasm_start();
    return 0;
}

extern "C" void fpc_browser_exit(int code) {
    MAIN_THREAD_EM_ASM(
        {
            if (Module['onGameExit'])
                Module['onGameExit']($0);
        },
        code);
}

extern "C" void fpc_browser_presented(void) {
    static bool first = true;
    if (first) {
        first = false;
        MAIN_THREAD_EM_ASM({
            if (Module['onGameReady'])
                Module['onGameReady']();
        });
    }
}

extern "C" void sr_fpc_memory_status(uint64_t *capacity, uint64_t *available) {
    // Browsers do not expose free host RAM. Report the finite linear-memory
    // budget: unused address space plus reusable blocks in the shared allocator.
    // Read the break after allocator statistics so concurrent growth cannot
    // count newly claimed arena space twice. These are capacity estimates;
    // browser memory pressure can still make growth fail before the maximum.
    const auto allocator = mallinfo();
    const uint64_t limit = emscripten_get_heap_max();
    const uint64_t program_break = reinterpret_cast<uintptr_t>(sbrk(0));
    *capacity = limit;
    *available = std::min(limit, limit - std::min(limit, program_break) + allocator.fordblks);
}
