// SDL owns the Java thread and JNI lifecycle. Load Pascal only after establishing
// app-private paths: FPC unit initialization must never see Android's root CWD.
#include <SDL.h>
#include <android/log.h>
#include <dlfcn.h>
#include <fcntl.h>
#include <jni.h>
#include <cerrno>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <unistd.h>

namespace {
int startup_error(const char *message) {
    __android_log_print(ANDROID_LOG_ERROR, "SRHD-FPC", "%s", message);
    std::fprintf(stderr, "%s\n", message);
    SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Space Rangers HD", message, nullptr);
    return 1;
}

int redirect_log(int directory, const char *name, const char *previous, int target) {
    // Preserve the preceding launch, including crashes, before opening a fresh log.
    if (renameat(directory, name, directory, previous) < 0 && errno != ENOENT)
        return -1;
    const int file = openat(directory, name, O_WRONLY | O_CREAT | O_TRUNC, 0600);
    if (file < 0)
        return -1;
    const int result = dup2(file, target);
    if (file != target)
        close(file);
    return result;
}

void post_input_event(Sint32 code, std::intptr_t value = 0) {
    SDL_Event event{};
    event.type = SDL_USEREVENT;
    event.user.code = code;
    event.user.data1 = reinterpret_cast<void *>(value);
    SDL_PushEvent(&event);
}

void arcade_controls_changed(void *, const char *, const char *, const char *value) {
    auto *env = static_cast<JNIEnv *>(SDL_AndroidGetJNIEnv());
    auto activity = static_cast<jobject>(SDL_AndroidGetActivity());
    if (!env || !activity)
        return;
    const auto type = env->GetObjectClass(activity);
    const auto method = env->GetMethodID(type, "setArcadeControls", "(I)V");
    if (method)
        env->CallVoidMethod(activity, method, value ? std::atoi(value) : 0);
    env->DeleteLocalRef(type);
    env->DeleteLocalRef(activity);
}
} // namespace

extern "C" int SDL_main(int argc, char **argv) {
    const char *game = nullptr, *user = nullptr;
    for (int i = 1; i + 1 < argc; ++i) {
        if (std::strcmp(argv[i], "--game-dir") == 0)
            game = argv[++i];
        else if (std::strcmp(argv[i], "--user-dir") == 0)
            user = argv[++i];
        else if (std::strcmp(argv[i], "--touch-slop") == 0)
            SDL_SetHint("SRHD_TOUCH_SLOP", argv[++i]);
        else if (std::strcmp(argv[i], "--ui-density") == 0)
            SDL_SetHint("SRHD_UI_DENSITY", argv[++i]);
    }
    if (!game || !user || game[0] != '/' || user[0] != '/')
        return startup_error("The Android launcher did not provide private data directories.");
    const int profile = open(user, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
    if (profile < 0)
        return startup_error("Cannot open the private save directory.");
    if (setenv("SR_USER_DIR", user, 1) || chdir(game)) {
        close(profile);
        return startup_error("Cannot open the imported game directory.");
    }

    const int out = redirect_log(profile, "stdout.log", "stdout.previous.log", STDOUT_FILENO);
    const int err = redirect_log(profile, "stderr.log", "stderr.previous.log", STDERR_FILENO);
    close(profile);
    if (out < 0 || err < 0)
        return startup_error(
            "Cannot create startup logs in the private save directory. Check available storage.");
    std::setvbuf(stdout, nullptr, _IONBF, 0);
    std::setvbuf(stderr, nullptr, _IONBF, 0);

    // SDLActivity intentionally does not load Rangers in getLibraries(): its
    // Pascal initialization belongs on SDL's game thread after chdir/setenv.
    void *library = dlopen("libRangers.so", RTLD_NOW | RTLD_LOCAL);
    if (!library)
        return startup_error(dlerror());
    using GameMain = int (*)(int, char **);
    const auto entry = reinterpret_cast<GameMain>(dlsym(library, "sr_fpc_main"));
    if (!entry)
        return startup_error("libRangers.so does not export sr_fpc_main.");
    // SDL frees its argument array when main returns, but System.argv and FPC
    // finalizers can still refer to it. This private game process owns the copy
    // and library until teardown; do not dlclose active Pascal runtime code.
    auto arguments =
        static_cast<char **>(std::calloc(static_cast<size_t>(argc) + 1, sizeof(char *)));
    if (!arguments)
        return startup_error("Cannot allocate game arguments.");
    for (int i = 0; i < argc; ++i) {
        arguments[i] = strdup(argv[i]);
        if (!arguments[i]) {
            while (i > 0)
                std::free(arguments[--i]);
            std::free(arguments);
            return startup_error("Cannot copy game arguments.");
        }
    }
    SDL_AddHintCallback("SRHD_ARCADE_CONTROLS", arcade_controls_changed, nullptr);
    const int result = entry(argc, arguments);
    SDL_DelHintCallback("SRHD_ARCADE_CONTROLS", arcade_controls_changed, nullptr);
    if (result != 0)
        startup_error(
            "The game stopped with an error. Return to the launcher and use Export saves for diagnostics.");
    return result;
}

extern "C" JNIEXPORT void JNICALL
Java_io_github_pakompom_spacerangershd_GameActivity_nativeCancelTouch(JNIEnv *, jclass) {
    post_input_event(0x53524354); // SRCT: cancel before SDL maps CANCEL to UP.
}

extern "C" JNIEXPORT void JNICALL
Java_io_github_pakompom_spacerangershd_GameActivity_nativeInputMode(JNIEnv *, jclass, jint flags) {
    post_input_event(0x5352494d, flags & 3); // SRIM: right-click=1, hover-only=2.
}

extern "C" JNIEXPORT void JNICALL
Java_io_github_pakompom_spacerangershd_GameActivity_nativeScroll(JNIEnv *, jclass, jint direction) {
    post_input_event(0x53525343, direction); // SRSC: scroll at the game's virtual cursor.
}

extern "C" JNIEXPORT void JNICALL
Java_io_github_pakompom_spacerangershd_GameActivity_nativeDensityChanged(JNIEnv *, jclass,
                                                                         jint densityDpi) {
    // SDL2 hints are not thread-safe. The game thread applies this update.
    if (densityDpi > 0)
        post_input_event(0x53524444, densityDpi); // SRDD: Android density, in dpi.
}

extern "C" JNIEXPORT void JNICALL
Java_io_github_pakompom_spacerangershd_GameActivity_nativeArcadeInput(JNIEnv *, jclass,
                                                                      jint controls, jint axes,
                                                                      jint buttons) {
    SDL_Event event{};
    event.type = SDL_USEREVENT;
    event.user.code = 0x53524143; // SRAC: screen-direction axes and fire state.
    event.user.data1 = reinterpret_cast<void *>(static_cast<std::intptr_t>(axes));
    event.user.data2 = reinterpret_cast<void *>(
        static_cast<std::intptr_t>((controls & 0x7fffff00) | (buttons & 3)));
    SDL_PushEvent(&event);
}
