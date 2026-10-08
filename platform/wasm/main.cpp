#include "fpc_wasi.h"
#include <algorithm>
#include <atomic>
#include <cstdint>
#include <emscripten.h>
#include <emscripten/heap.h>
#include <emscripten/html5.h>
#include <emscripten/proxying.h>
#include <emscripten/threading.h>
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

namespace {
emscripten::ProxyingQueue frame_queue;
std::atomic<uint32_t> completed_frame{0};
static_assert(std::atomic<uint32_t>::is_always_lock_free &&
              sizeof(completed_frame) == sizeof(uint32_t));
uint32_t next_frame = 0; // Application pthread only.
// Request state belongs to the browser thread. Tokens, rather than stack
// pointers, make even an obsolete callback harmless after a canceled request.
uint32_t pending_frame = 0;
int animation_request = 0;
bool frame_pending = false;

bool animation_frame(double, void *token) {
    const auto frame = static_cast<uint32_t>(reinterpret_cast<uintptr_t>(token));
    if (!frame_pending || pending_frame != frame)
        return false;
    frame_pending = false;
    completed_frame.store(frame, std::memory_order_release);
    emscripten_futex_wake(&completed_frame, 1);
    return false;
}
} // namespace

extern "C" void fpc_browser_wait_frame(void) {
    // The blocking Pascal loop runs on the application pthread. Only request
    // registration/cancellation runs on the browser thread; it must never wait.
    const auto browser = emscripten_main_runtime_thread_id();
    const uint32_t frame = ++next_frame;
    if (!frame_queue.proxySync(browser, [frame] {
            pending_frame = frame;
            frame_pending = true;
            if (EM_ASM_INT({ return typeof globalThis.requestAnimationFrame == 'function'; })) {
                animation_request = emscripten_request_animation_frame(
                    animation_frame, reinterpret_cast<void *>(static_cast<uintptr_t>(frame)));
            } else {
                // A host without a display has no refresh callback to wait for.
                animation_frame(0, reinterpret_cast<void *>(static_cast<uintptr_t>(frame)));
            }
        }))
        return;

    // A hidden document can suspend rAF indefinitely. Bound the wait so the
    // game's own event loop can still handle focus, shutdown and reinitialization.
    const double deadline = emscripten_get_now() + 250;
    while (completed_frame.load(std::memory_order_acquire) != frame) {
        // Unlike thread_sleep, a raw futex wait does not drain this pthread's
        // SDL/system proxy queue. Preserve the previous loop's queue servicing.
        emscripten_current_thread_process_queued_calls();
        const double remaining = deadline - emscripten_get_now();
        if (remaining <= 0)
            break;
        const auto observed = completed_frame.load(std::memory_order_acquire);
        if (observed != frame)
            emscripten_futex_wait(&completed_frame, observed, std::min(remaining, 50.0));
    }
    if (completed_frame.load(std::memory_order_acquire) != frame) {
        frame_queue.proxySync(browser, [frame] {
            if (frame_pending && pending_frame == frame) {
                emscripten_cancel_animation_frame(animation_request);
                frame_pending = false;
            }
        });
    }
    emscripten_current_thread_process_queued_calls();
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
