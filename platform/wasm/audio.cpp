#include <SDL_audio.h>
#include <SDL_error.h>
#include <emscripten/proxying.h>
#include <emscripten/threading.h>
#include <cstdio>
#include <cstdlib>

namespace {
emscripten::ProxyingQueue audio_queue;

// SDL's browser backend has no mixer lock. Device creation/destruction and
// queue access must run on the same browser thread as its drain callback.
// Callers must release the Pascal mixer lock before entering this proxy.
template <class Function> void on_audio_thread(Function &&function) {
    if (emscripten_is_main_runtime_thread())
        function();
    else if (!audio_queue.proxySync(emscripten_main_runtime_thread_id(), function))
        std::abort();
}
} // namespace

extern "C" SDL_AudioDeviceID sr_fpc_open_audio_device(const char *device, int capture,
                                                      const SDL_AudioSpec *desired,
                                                      SDL_AudioSpec *obtained, int changes) {
    SDL_AudioDeviceID result;
    char error[256] = {};
    on_audio_thread([&] {
        result = SDL_OpenAudioDevice(device, capture, desired, obtained, changes);
        if (!result)
            std::snprintf(error, sizeof(error), "%s", SDL_GetError());
    });
    if (!result)
        SDL_SetError("%s", error);
    return result;
}

extern "C" void sr_fpc_close_audio_device(SDL_AudioDeviceID device) {
    // Proxy the entire close, not just the backend's JS disconnect: SDL frees
    // work_buffer and its conversion stream before calling that disconnect.
    on_audio_thread([&] { SDL_CloseAudioDevice(device); });
}

extern "C" int sr_fpc_queue_audio(SDL_AudioDeviceID device, const void *data, Uint32 length) {
    int result;
    char error[256] = {};
    on_audio_thread([&] {
        result = SDL_QueueAudio(device, data, length);
        if (result < 0)
            std::snprintf(error, sizeof(error), "%s", SDL_GetError());
    });
    // SDL errors belong to the calling thread, not the browser thread.
    if (result < 0)
        SDL_SetError("%s", error);
    return result;
}

extern "C" Uint32 sr_fpc_queued_audio_size(SDL_AudioDeviceID device) {
    Uint32 result;
    on_audio_thread([&] { result = SDL_GetQueuedAudioSize(device); });
    return result;
}
