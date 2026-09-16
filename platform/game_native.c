/* Native platform boundary. The recovered Pascal UI owns layout and RGB565 pixels. */
#include <SDL2/SDL.h>
#include <SDL2/SDL_mixer.h>
#include <stdint.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#ifndef _WIN32
#include <sys/resource.h>
#endif
#ifdef __APPLE__
#include <mach/mach.h>
#elif !defined(_WIN32)
#include <sys/sysinfo.h>
#include <unistd.h>
#endif
#ifdef __ANDROID__
#include "android_native.h"
#endif
#include <time.h>
#include <errno.h>
static SDL_Window *window;
static SDL_Renderer *renderer;
static SDL_Texture *texture;
static int logical_w, logical_h;
static int audio_ready;
static int headless;
static int system_cursor_visible;
static Uint16 text_units[SDL_TEXTINPUTEVENT_TEXT_SIZE];
static int text_position, text_count;
static uint64_t presented_frames;
static uint16_t display_gamma[65536];
static uint16_t *gamma_pixels;
static size_t gamma_capacity;
static int gamma_enabled;
#include "game_gpu.inc.c"
static void apply_cursor_visibility(void) {
    if (headless)
        return;
    int visible = system_cursor_visible ? SDL_ENABLE : SDL_DISABLE;
    /* App switching can restore Cocoa's arrow without changing SDL's cached
       visibility. Force a redraw when ShowCursor would otherwise do nothing. */
    if (SDL_ShowCursor(visible) == visible)
        SDL_SetCursor(NULL);
}
void sr_set_gamma(const uint16_t *red, const uint16_t *green, const uint16_t *blue) {
    gamma_enabled = 0;
    for (unsigned pixel = 0; pixel < 65536; pixel++) {
        unsigned r = ((pixel >> 11) * 255 + 15) / 31, g = (((pixel >> 5) & 63) * 255 + 31) / 63,
                 b = ((pixel & 31) * 255 + 15) / 31;
        uint16_t mapped = (uint16_t)((((uint32_t)red[r] * 31 + 32767) / 65535) << 11 |
                                     (((uint32_t)green[g] * 63 + 32767) / 65535) << 5 |
                                     (((uint32_t)blue[b] * 31 + 32767) / 65535));
        display_gamma[pixel] = mapped;
        if (mapped != pixel)
            gamma_enabled = 1;
    }
}
int sr_window_options(int windowed, int vsync) {
    if (headless)
        return 1;
#ifdef __ANDROID__
    windowed = 0;
#endif
    if (!window ||
        SDL_SetWindowFullscreen(window, windowed ? 0 : SDL_WINDOW_FULLSCREEN_DESKTOP) < 0)
        return 0;
    apply_cursor_visibility();
    return SDL_RenderSetVSync(renderer, vsync) == 0;
}
void sr_set_headless(int value) { headless = value; }
int sr_is_headless(void) { return headless; }
int sr_window_focused(void) {
    return headless || (window && (SDL_GetWindowFlags(window) & SDL_WINDOW_INPUT_FOCUS));
}
int sr_double_click_ms(void) {
    const char *value = SDL_GetHint(SDL_HINT_MOUSE_DOUBLE_CLICK_TIME);
    return value ? SDL_atoi(value) : 500;
}
const char *sr_error(void) { return SDL_GetError(); }
int sr_display_size(int *w, int *h) {
    SDL_DisplayMode mode;
    if (headless || SDL_InitSubSystem(SDL_INIT_VIDEO) < 0 ||
        SDL_GetCurrentDisplayMode(0, &mode) < 0)
        return 0;
    *w = mode.w;
    *h = mode.h;
    return *w > 0 && *h > 0;
}
int sr_display_mode_count(void) {
    if (headless || SDL_InitSubSystem(SDL_INIT_VIDEO) < 0)
        return 0;
    return SDL_GetNumDisplayModes(0);
}
int sr_display_mode(int index, unsigned *w, unsigned *h, unsigned *refresh) {
    SDL_DisplayMode mode;
    if (headless || SDL_InitSubSystem(SDL_INIT_VIDEO) < 0)
        return 0;
    int result =
        index < 0 ? SDL_GetCurrentDisplayMode(0, &mode) : SDL_GetDisplayMode(0, index, &mode);
    if (result < 0)
        return 0;
    *w = mode.w;
    *h = mode.h;
    *refresh = mode.refresh_rate;
    return 1;
}
int sr_window_open(int w, int h) {
    if (headless) {
        logical_w = w;
        logical_h = h;
        return gpu_requested ? (SDL_SetError("--renderer=sdl requires a visible window"), 0) : 1;
    }
    if (SDL_InitSubSystem(SDL_INIT_VIDEO | SDL_INIT_TIMER) < 0)
        return 0;
#ifdef __ANDROID__
    SDL_SetHint(SDL_HINT_ORIENTATIONS, "LandscapeLeft LandscapeRight");
#endif
    logical_w = w;
    logical_h = h;
    window = SDL_CreateWindow("Rangers", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, w, h,
                              SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI);
    if (!window)
        return 0;
    apply_cursor_visibility();
    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (!renderer && !gpu_requested)
        renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_SOFTWARE);
    if (!renderer)
        return 0;
    SDL_RenderSetLogicalSize(renderer, w, h);
    texture =
        SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGB565, SDL_TEXTUREACCESS_STREAMING, w, h);
#ifndef __ANDROID__
    SDL_StartTextInput();
#endif
    return texture != NULL && (!gpu_requested || gpu_open());
}
void sr_window_close(void) {
    gpu_close();
    if (texture)
        SDL_DestroyTexture(texture);
    if (renderer)
        SDL_DestroyRenderer(renderer);
    if (window)
        SDL_DestroyWindow(window);
    texture = NULL;
    renderer = NULL;
    window = NULL;
    text_position = text_count = 0;
    free(gamma_pixels);
    gamma_pixels = NULL;
    gamma_capacity = 0;
    SDL_QuitSubSystem(SDL_INIT_VIDEO);
}
int sr_present(const void *pixels, int pitch) {
    if (headless)
        return pixels && pitch >= logical_w * 2;
    if (gamma_enabled) {
        size_t count = (size_t)logical_w * logical_h;
        if (count > gamma_capacity) {
            uint16_t *next = realloc(gamma_pixels, count * sizeof(*next));
            if (!next) {
                SDL_OutOfMemory();
                return 0;
            }
            gamma_pixels = next;
            gamma_capacity = count;
        }
        for (int y = 0; y < logical_h; y++) {
            const uint16_t *source = (const uint16_t *)((const uint8_t *)pixels + y * pitch);
            for (int x = 0; x < logical_w; x++)
                gamma_pixels[(size_t)y * logical_w + x] = display_gamma[source[x]];
        }
        pixels = gamma_pixels;
        pitch = logical_w * 2;
    }
    if (!texture || SDL_UpdateTexture(texture, NULL, pixels, pitch) < 0)
        return 0;

    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    SDL_RenderClear(renderer);
    if (SDL_RenderCopy(renderer, texture, NULL, NULL) < 0)
        return 0;
    SDL_RenderPresent(renderer);
    presented_frames++;
    return 1;
}
uint64_t sr_present_count(void) { return presented_frames; }
/* Game shortcuts use physical keys even when the text layout is Cyrillic. */
static int vk(SDL_Scancode k) {
    if (k >= SDL_SCANCODE_A && k <= SDL_SCANCODE_Z)
        return k - SDL_SCANCODE_A + 'A';
    if (k >= SDL_SCANCODE_1 && k <= SDL_SCANCODE_9)
        return k - SDL_SCANCODE_1 + '1';
    if (k >= SDL_SCANCODE_F1 && k <= SDL_SCANCODE_F12)
        return k - SDL_SCANCODE_F1 + 112;
    if (k >= SDL_SCANCODE_KP_1 && k <= SDL_SCANCODE_KP_9)
        return k - SDL_SCANCODE_KP_1 + 97;
    switch (k) {
    case SDL_SCANCODE_LSHIFT:
    case SDL_SCANCODE_RSHIFT:
        return 16;
    case SDL_SCANCODE_LCTRL:
    case SDL_SCANCODE_RCTRL:
        return 17;
    case SDL_SCANCODE_LALT:
    case SDL_SCANCODE_RALT:
        return 18;
    case SDL_SCANCODE_LEFT:
        return 37;
    case SDL_SCANCODE_UP:
        return 38;
    case SDL_SCANCODE_RIGHT:
        return 39;
    case SDL_SCANCODE_DOWN:
        return 40;
    case SDL_SCANCODE_HOME:
        return 36;
    case SDL_SCANCODE_END:
        return 35;
    case SDL_SCANCODE_PAGEUP:
        return 33;
    case SDL_SCANCODE_PAGEDOWN:
        return 34;
    case SDL_SCANCODE_DELETE:
        return 46;
    case SDL_SCANCODE_INSERT:
        return 45;
    case SDL_SCANCODE_RETURN:
    case SDL_SCANCODE_KP_ENTER:
        return 13;
    case SDL_SCANCODE_ESCAPE:
        return 27;
    case SDL_SCANCODE_SPACE:
        return 32;
    case SDL_SCANCODE_BACKSPACE:
        return 8;
    case SDL_SCANCODE_TAB:
        return 9;
    case SDL_SCANCODE_0:
        return '0';
    case SDL_SCANCODE_KP_0:
        return 96;
    case SDL_SCANCODE_CAPSLOCK:
        return 20;
    case SDL_SCANCODE_PAUSE:
        return 19;
    case SDL_SCANCODE_MINUS:
        return 189;
    case SDL_SCANCODE_EQUALS:
        return 187;
    case SDL_SCANCODE_LEFTBRACKET:
        return 219;
    case SDL_SCANCODE_RIGHTBRACKET:
        return 221;
    case SDL_SCANCODE_BACKSLASH:
        return 220;
    case SDL_SCANCODE_SEMICOLON:
        return 186;
    case SDL_SCANCODE_APOSTROPHE:
        return 222;
    case SDL_SCANCODE_GRAVE:
        return 192;
    case SDL_SCANCODE_COMMA:
        return 188;
    case SDL_SCANCODE_PERIOD:
        return 190;
    case SDL_SCANCODE_SLASH:
        return 191;
    case SDL_SCANCODE_KP_PLUS:
        return 107;
    case SDL_SCANCODE_KP_MINUS:
        return 109;
    case SDL_SCANCODE_KP_MULTIPLY:
        return 106;
    case SDL_SCANCODE_KP_DIVIDE:
        return 111;
    case SDL_SCANCODE_KP_PERIOD:
        return 110;
    default:
        return 0;
    }
}
/* GPU drawing leaves an unscaled offscreen target selected. SDL's automatic
   logical event transform is therefore disabled; use the window's letterbox
   explicitly. Window sizes/coordinates are points, including Retina displays. */
static float gpu_window_scale(int *offset_x, int *offset_y) {
    int w, h;
    SDL_GetWindowSize(window, &w, &h);
    float scale = SDL_min((float)w / logical_w, (float)h / logical_h);
    if (scale <= 0)
        scale = 1;
    *offset_x = (int)floorf((w - logical_w * scale) * 0.5f);
    *offset_y = (int)floorf((h - logical_h * scale) * 0.5f);
    return scale;
}
static void gpu_window_to_game(int *x, int *y) {
    int ox, oy;
    float scale = gpu_window_scale(&ox, &oy);
    *x = (int)floorf((*x - ox) / scale);
    *y = (int)floorf((*y - oy) / scale);
}
static int32_t event_point(int x, int y);
void sr_mouse(int *x, int *y) {
    if (headless) {
        *x = 0;
        *y = 0;
        return;
    }
    int mx, my;
    float fx, fy;
    SDL_GetMouseState(&mx, &my);
    if (gpu_active) {
        gpu_window_to_game(&mx, &my);
        *x = mx;
        *y = my;
    } else if (renderer) {
        SDL_RenderWindowToLogical(renderer, mx, my, &fx, &fy);
        *x = (int)fx;
        *y = (int)fy;
    } else {
        *x = mx;
        *y = my;
    }
}
void sr_warp(int x, int y) {
    int wx = x, wy = y;
    if (gpu_active) {
        int ox, oy;
        float scale = gpu_window_scale(&ox, &oy);
        wx = (int)lroundf(x * scale + ox);
        wy = (int)lroundf(y * scale + oy);
    } else if (renderer)
        SDL_RenderLogicalToWindow(renderer, (float)x, (float)y, &wx, &wy);
    if (window)
        SDL_WarpMouseInWindow(window, wx, wy);
}
void sr_cursor(int visible) {
    system_cursor_visible = visible != 0;
    apply_cursor_visibility();
}
int sr_key(int key) {
#ifdef __ANDROID__
    if (sr_android_key(key))
        return 0x8000;
#endif
    int n;
    const Uint8 *keys = SDL_GetKeyboardState(&n);
    if (key == 1 || key == 2 || key == 4) {
        Uint32 b = SDL_GetMouseState(NULL, NULL);
#ifdef __ANDROID__
        if (sr_android_hover())
            b &= ~SDL_BUTTON_LMASK;
        if (sr_android_right() && (b & SDL_BUTTON_LMASK))
            b = (b & ~SDL_BUTTON_LMASK) | SDL_BUTTON_RMASK;
#endif
        return (b & SDL_BUTTON(key == 1 ? 1 : key == 2 ? 3 : 2)) ? 0x8000 : 0;
    }
    for (int i = 0; i < n; i++)
        if (keys[i] && vk((SDL_Scancode)i) == key)
            return 0x8000;
    return 0;
}
/* Fixed-width event ABI, independent of SDL's union layout. */
typedef struct SrEvent {
    uint32_t message, wparam;
    int32_t lparam;
} SrEvent;
static int32_t pack_point(int x, int y) {
    return (int32_t)((uint32_t)(uint16_t)x | ((uint32_t)(uint16_t)y << 16));
}
static int32_t event_point(int x, int y) {
    if (gpu_active)
        gpu_window_to_game(&x, &y);
    return pack_point(x, y);
}
static double wheel_remaining;
static SrEvent wheel_event;
static int emit_wheel(SrEvent *out) {
    if (fabs(wheel_remaining) < 1.0)
        return 0;
    int step = wheel_remaining > 0 ? 1 : -1;
    wheel_remaining -= step;
    *out = wheel_event;
    out->wparam |= (uint32_t)(uint16_t)(step * 120) << 16;
    return 1;
}
static void queue_wheel(const SDL_MouseWheelEvent *e, uint32_t keys) {
    double amount = e->preciseY != 0 ? e->preciseY : e->y;
    if (!isfinite(amount))
        return;
    /* Cocoa/SDL already applies the user's natural-scroll preference to the
       delta. FLIPPED describes that adjustment; undoing it reverses menus. */
    wheel_remaining += amount;
    wheel_event.message = 0x20a;
    wheel_event.wparam = keys;
    /* SDL_RenderSetLogicalSize already transforms these event coordinates. */
    wheel_event.lparam = event_point(e->mouseX, e->mouseY);
}
int sr_post(uint32_t message, uint32_t wparam, int32_t lparam) {
    if (headless || !window)
        return 1;
    SDL_Event e = {0};
    e.type = SDL_USEREVENT;
    e.user.code = (int32_t)message;
    e.user.data1 = (void *)(uintptr_t)wparam;
    e.user.data2 = (void *)(intptr_t)lparam;
    return SDL_PushEvent(&e) > 0;
}
static uint32_t mouse_keys_from_state(Uint32 b) {
#ifdef __ANDROID__
    if (sr_android_hover())
        b &= ~SDL_BUTTON_LMASK;
    if (sr_android_right() && (b & SDL_BUTTON_LMASK))
        b = (b & ~SDL_BUTTON_LMASK) | SDL_BUTTON_RMASK;
#endif
    uint32_t r = 0;
    SDL_Keymod mod = SDL_GetModState();
    if (b & SDL_BUTTON_LMASK)
        r |= 1;
    if (b & SDL_BUTTON_RMASK)
        r |= 2;
    if (b & SDL_BUTTON_MMASK)
        r |= 16;
    if (mod & KMOD_SHIFT)
        r |= 4;
    if (mod & KMOD_CTRL)
        r |= 8;
    return r;
}
static uint32_t mouse_keys(void) { return mouse_keys_from_state(SDL_GetMouseState(NULL, NULL)); }
/* SDL commits UTF-8 strings; the recovered WM_CHAR path consumes UTF-16 units. */
static void queue_text(const char *text) {
    Uint16 *converted = (Uint16 *)SDL_iconv_string("UTF-16LE", "UTF-8", text, SDL_strlen(text) + 1);
    text_position = text_count = 0;
    if (!converted)
        return;
    while (text_count < SDL_TEXTINPUTEVENT_TEXT_SIZE && converted[text_count]) {
        text_units[text_count] = SDL_SwapLE16(converted[text_count]);
        text_count++;
    }
    SDL_free(converted);
}
static int emit_text(SrEvent *out) {
    if (text_position == text_count)
        return 0;
    out->message = 0x102;
    out->wparam = text_units[text_position++];
    out->lparam = 1;
    return 1;
}
int sr_poll(SrEvent *out) {
    SDL_Event e;
    if (emit_text(out))
        return 1;
    if (emit_wheel(out))
        return 1;
    while (SDL_PollEvent(&e)) {
        memset(out, 0, sizeof(*out));
        switch (e.type) {
        case SDL_USEREVENT:
            out->message = e.user.code;
            out->wparam = (uint32_t)(uintptr_t)e.user.data1;
            out->lparam = (int32_t)(intptr_t)e.user.data2;
            return 1;
        case SDL_QUIT:
            out->message = 0x10;
            return 1;
        case SDL_KEYDOWN:
        case SDL_KEYUP:
            out->message = e.type == SDL_KEYDOWN ? 0x100 : 0x101;
            out->wparam = vk(e.key.keysym.scancode);
            if (e.key.repeat)
                out->lparam = 1 << 30;
            if (out->wparam)
                return 1;
            break;
        case SDL_TEXTINPUT:
            queue_text(e.text.text);
            if (emit_text(out))
                return 1;
            break;
        /* Logical-size rendering already transforms coordinates in SDL events.
           Keep each event's position even when the cursor has since moved. */
        case SDL_MOUSEMOTION:
            apply_cursor_visibility();
            out->message = 0x200;
            out->wparam = mouse_keys_from_state(e.motion.state);
            out->lparam = event_point(e.motion.x, e.motion.y);
            return 1;
        case SDL_MOUSEBUTTONDOWN:
        case SDL_MOUSEBUTTONUP: {
#ifdef __ANDROID__
            if (e.button.button == SDL_BUTTON_LEFT && sr_android_hover()) {
                out->message = 0x200;
                out->lparam = event_point(e.button.x, e.button.y);
                return 1;
            }
            if (e.button.button == SDL_BUTTON_LEFT && sr_android_right())
                e.button.button = SDL_BUTTON_RIGHT;
#endif
            uint32_t button = e.button.button == SDL_BUTTON_LEFT    ? 1
                              : e.button.button == SDL_BUTTON_RIGHT ? 2
                                                                    : 16;
            out->wparam = mouse_keys();
            out->lparam = event_point(e.button.x, e.button.y);
            if (e.type == SDL_MOUSEBUTTONDOWN)
                out->wparam |= button;
            else
                out->wparam &= ~button;
            out->message = e.button.button == SDL_BUTTON_LEFT    ? 0x201
                           : e.button.button == SDL_BUTTON_RIGHT ? 0x204
                                                                 : 0x207;
            if (e.type == SDL_MOUSEBUTTONUP)
                out->message++;
            else if (e.button.clicks >= 2)
                out->message += 2;
            return 1;
        }
        case SDL_MOUSEWHEEL:
            queue_wheel(&e.wheel, mouse_keys());
            if (emit_wheel(out))
                return 1;
            break;
        case SDL_WINDOWEVENT:
            if (e.window.event == SDL_WINDOWEVENT_ENTER ||
                e.window.event == SDL_WINDOWEVENT_FOCUS_GAINED)
                apply_cursor_visibility();
            if (e.window.event == SDL_WINDOWEVENT_CLOSE) {
                out->message = 0x10;
                return 1;
            }
            if (e.window.event == SDL_WINDOWEVENT_EXPOSED) {
                out->message = 0xf;
                return 1;
            }
            if (e.window.event == SDL_WINDOWEVENT_FOCUS_GAINED ||
                e.window.event == SDL_WINDOWEVENT_FOCUS_LOST) {
                out->message = 0x1c;
                out->wparam = e.window.event == SDL_WINDOWEVENT_FOCUS_GAINED;
                return 1;
            }
            break;
#ifdef __ANDROID__
        case SDL_RENDER_DEVICE_RESET:
            if (!gpu_requested) {
                if (texture)
                    SDL_DestroyTexture(texture);
                texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGB565,
                                            SDL_TEXTUREACCESS_STREAMING, logical_w, logical_h);
                out->message = 0xf;
                return 1;
            }
            break;
#endif
        }
    }
    return 0;
}
/* SDL can display a Cocoa alert before video/window initialization too. */
int sr_message_box(const char *text, const char *title, uint32_t flags) {
    SDL_MessageBoxButtonData buttons[3];
    int count = 0, cancel = 1;
    const char *labels[3];
    int ids[3];
    switch (flags & 15) {
    case 1:
        count = 2;
        ids[0] = 1;
        labels[0] = "OK";
        ids[1] = 2;
        labels[1] = "Cancel";
        cancel = 2;
        break;
    case 2:
        count = 3;
        ids[0] = 3;
        labels[0] = "Abort";
        ids[1] = 4;
        labels[1] = "Retry";
        ids[2] = 5;
        labels[2] = "Ignore";
        cancel = 3;
        break;
    case 3:
        count = 3;
        ids[0] = 6;
        labels[0] = "Yes";
        ids[1] = 7;
        labels[1] = "No";
        ids[2] = 2;
        labels[2] = "Cancel";
        cancel = 2;
        break;
    case 4:
        count = 2;
        ids[0] = 6;
        labels[0] = "Yes";
        ids[1] = 7;
        labels[1] = "No";
        cancel = 7;
        break;
    case 5:
        count = 2;
        ids[0] = 4;
        labels[0] = "Retry";
        ids[1] = 2;
        labels[1] = "Cancel";
        cancel = 2;
        break;
    case 6:
        count = 3;
        ids[0] = 2;
        labels[0] = "Cancel";
        ids[1] = 10;
        labels[1] = "Try Again";
        ids[2] = 11;
        labels[2] = "Continue";
        cancel = 2;
        break;
    default:
        count = 1;
        ids[0] = 1;
        labels[0] = "OK";
        break;
    }
    if (headless)
        return cancel;
    int selected = (flags >> 8) & 3;
    if (selected >= count)
        selected = 0;
    for (int i = 0; i < count; i++) {
        buttons[i].buttonid = ids[i];
        buttons[i].text = labels[i];
        buttons[i].flags = 0;
        if (i == selected)
            buttons[i].flags |= SDL_MESSAGEBOX_BUTTON_RETURNKEY_DEFAULT;
        if (ids[i] == cancel)
            buttons[i].flags |= SDL_MESSAGEBOX_BUTTON_ESCAPEKEY_DEFAULT;
    }
    Uint32 style = (flags & 0xf0) == 0x10   ? SDL_MESSAGEBOX_ERROR
                   : (flags & 0xf0) == 0x30 ? SDL_MESSAGEBOX_WARNING
                                            : SDL_MESSAGEBOX_INFORMATION;
    SDL_MessageBoxData data = {style, window, title, text, count, buttons, NULL};
    int answer = cancel;
    if (SDL_ShowMessageBox(&data, &answer) < 0)
        return 0;
    return answer < 0 ? cancel : answer;
}
int sr_audio_open(void) {
    if (audio_ready)
        return 1;
    if (SDL_InitSubSystem(SDL_INIT_AUDIO) < 0)
        return 0;
    Mix_Init(MIX_INIT_OGG);
    if (Mix_OpenAudio(44100, AUDIO_S16SYS, 2, 1024) < 0)
        return 0;
    Mix_AllocateChannels(64);
    audio_ready = 1;
    return 1;
}
void sr_audio_close(void) {
    if (audio_ready) {
        Mix_HaltMusic();
        Mix_HaltChannel(-1);
        Mix_CloseAudio();
        Mix_Quit();
        audio_ready = 0;
    }
}
/* DirectSound units are hundredths of a decibel, not linear amplitudes. */
static float attenuation_gain(int db) {
    if (db <= -10000)
        return 0;
    return powf(10.0f, SDL_min(db, 0) / 2000.0f);
}
static int mixer_volume(int db) { return (int)lroundf(MIX_MAX_VOLUME * attenuation_gain(db)); }
typedef struct SrSound {
    Mix_Chunk *chunk;
    int channel, volume_db, pan_db;
} SrSound;
void *sr_sound_create(const void *pcm, int size, int rate, int channels, int bits) {
    if (!sr_audio_open())
        return NULL;
    SDL_AudioCVT cvt;
    if (SDL_BuildAudioCVT(&cvt, bits == 8 ? AUDIO_U8 : AUDIO_S16LSB, channels, rate, AUDIO_S16SYS,
                          2, 44100) < 0)
        return NULL;
    cvt.len = size;
    cvt.buf = SDL_malloc((size_t)size * cvt.len_mult);
    if (!cvt.buf)
        return NULL;
    memcpy(cvt.buf, pcm, size);
    if (SDL_ConvertAudio(&cvt) < 0) {
        SDL_free(cvt.buf);
        return NULL;
    }
    SrSound *s = calloc(1, sizeof(*s));
    if (!s) {
        SDL_free(cvt.buf);
        SDL_OutOfMemory();
        return NULL;
    }
    s->channel = -1;
    s->chunk = Mix_QuickLoad_RAW(cvt.buf, cvt.len_cvt);
    if (!s->chunk) {
        SDL_free(cvt.buf);
        free(s);
        return NULL;
    }
    return s;
}
int sr_sound_playing(void *p) {
    SrSound *s = p;
    return s && s->channel >= 0 && Mix_Playing(s->channel) && Mix_GetChunk(s->channel) == s->chunk;
}
void sr_sound_stop(void *p) {
    SrSound *s = p;
    if (sr_sound_playing(s))
        Mix_HaltChannel(s->channel);
    if (s)
        s->channel = -1;
}
void sr_sound_free(void *p) {
    SrSound *s = p;
    if (!s)
        return;
    sr_sound_stop(s);
    void *buf = s->chunk->abuf;
    Mix_FreeChunk(s->chunk);
    SDL_free(buf);
    free(s);
}
static void sound_pan(SrSound *s, int channel) {
    int pan = SDL_clamp(s->pan_db, -10000, 10000);
    Uint8 left = (Uint8)lroundf(255 * attenuation_gain(pan > 0 ? -pan : 0));
    Uint8 right = (Uint8)lroundf(255 * attenuation_gain(pan < 0 ? pan : 0));
    Mix_SetPanning(channel, left, right);
}
void sr_sound_volume(void *p, int volume_db, int pan_db) {
    SrSound *s = p;
    if (!s)
        return;
    s->volume_db = volume_db;
    s->pan_db = pan_db;
    Mix_VolumeChunk(s->chunk, mixer_volume(volume_db));
    if (sr_sound_playing(s))
        sound_pan(s, s->channel);
}
int sr_sound_play(void *p, int loop) {
    SrSound *s = p;
    if (!s)
        return 0;
    sr_sound_stop(s);
    int channel = Mix_GroupAvailable(-1);
    if (channel < 0) {
        SDL_SetError("No free sound channel");
        return 0;
    }
    /* Reset recycled channel state and apply pan before its first samples. */
    Mix_Volume(channel, MIX_MAX_VOLUME);
    sound_pan(s, channel);
    s->channel = Mix_PlayChannel(channel, s->chunk, loop ? -1 : 0);
    return s->channel >= 0;
}
static Mix_Music *music;
void *sr_music_load(const void *data, int size) {
    if (!sr_audio_open())
        return NULL;
    SDL_RWops *source = SDL_RWFromConstMem(data, size);
    if (!source)
        return NULL;
    return Mix_LoadMUS_RW(source, 1);
}
void sr_music_stop(void) {
    if (audio_ready)
        Mix_HaltMusic();
    music = NULL;
}
void sr_music_free(void *p) {
    if (!p)
        return;
    if (p == music)
        sr_music_stop();
    Mix_FreeMusic(p);
}
int sr_music_start(void *p, int volume_db) {
    if (!p || !sr_audio_open())
        return 0;
    sr_music_stop();
    Mix_VolumeMusic(mixer_volume(volume_db));
    if (Mix_PlayMusic(p, 0) < 0)
        return 0;
    music = p;
    return 1;
}
void sr_music_volume(int volume_db) {
    if (audio_ready)
        Mix_VolumeMusic(mixer_volume(volume_db));
}
int sr_music_playing(void) { return audio_ready && music && Mix_PlayingMusic(); }
double sr_music_remaining(void *p) {
    if (!p || p != music)
        return -1;
    double duration = Mix_MusicDuration(p), position = Mix_GetMusicPosition(p);
    return duration >= 0 && position >= 0 ? SDL_max(0.0, duration - position) : -1;
}
#include <sys/types.h>
#ifdef __APPLE__
#include <sys/sysctl.h>
#include <mach/mach.h>
#endif
/* Windows reads memory in windows_native.c, keeping <windows.h> out of this unit. */
#ifndef _WIN32
void sr_memory(uint64_t *total, uint64_t *available) {
#ifdef __APPLE__
    size_t size = sizeof(*total);
    *total = 0;
    *available = 0;
    sysctlbyname("hw.memsize", total, &size, NULL, 0);
    vm_statistics64_data_t stats;
    mach_msg_type_number_t count = HOST_VM_INFO64_COUNT;
    vm_size_t page;
    host_page_size(mach_host_self(), &page);
    if (host_statistics64(mach_host_self(), HOST_VM_INFO64, (host_info64_t)&stats, &count) ==
        KERN_SUCCESS)
        *available = (uint64_t)(stats.free_count + stats.inactive_count) * page;
#else
    struct sysinfo info;
    *total = 0;
    *available = 0;
    if (sysinfo(&info) == 0) {
        *total = (uint64_t)info.totalram * info.mem_unit;
        *available = (uint64_t)(info.freeram + info.bufferram) * info.mem_unit;
    }
#endif
}
#endif

#include <stdio.h>
#include <setjmp.h>
#include <jpeglib.h>
typedef struct SrJpegError {
    struct jpeg_error_mgr base;
    jmp_buf jump;
} SrJpegError;
static void jpeg_failure(j_common_ptr info) {
    SrJpegError *e = (SrJpegError *)info->err;
    longjmp(e->jump, 1);
}
int sr_save_jpeg(const char *path, const void *pixels, int width, int height, int pitch, int bpp,
                 int quality) {
    if (width <= 0 || height <= 0 || (bpp != 2 && bpp != 3 && bpp != 4))
        return 0;
    FILE *f = fopen(path, "wb");
    if (!f)
        return 0;
    struct jpeg_compress_struct c = {0};
    SrJpegError e;
    uint8_t *row = malloc((size_t)width * 3);
    if (!row) {
        fclose(f);
        return 0;
    }
    c.err = jpeg_std_error(&e.base);
    e.base.error_exit = jpeg_failure;
    if (setjmp(e.jump)) {
        jpeg_destroy_compress(&c);
        free(row);
        fclose(f);
        return 0;
    }
    jpeg_create_compress(&c);
    jpeg_stdio_dest(&c, f);
    c.image_width = width;
    c.image_height = height;
    c.input_components = 3;
    c.in_color_space = JCS_RGB;
    jpeg_set_defaults(&c);
    jpeg_set_quality(&c, quality, TRUE);
    jpeg_start_compress(&c, TRUE);
    while (c.next_scanline < c.image_height) {
        const uint8_t *src = (const uint8_t *)pixels + c.next_scanline * pitch;
        for (int x = 0; x < width; x++) {
            if (bpp == 2) {
                uint16_t p;
                memcpy(&p, src + x * 2, 2);
                row[x * 3] = (p >> 11) * 255 / 31;
                row[x * 3 + 1] = ((p >> 5) & 63) * 255 / 63;
                row[x * 3 + 2] = (p & 31) * 255 / 31;
            } else {
                row[x * 3] = src[x * bpp + 2];
                row[x * 3 + 1] = src[x * bpp + 1];
                row[x * 3 + 2] = src[x * bpp];
            }
        }
        JSAMPROW rows[] = {row};
        jpeg_write_scanlines(&c, rows, 1);
    }
    jpeg_finish_compress(&c);
    jpeg_destroy_compress(&c);
    free(row);
    fclose(f);
    return 1;
}

const char *sr_clipboard_get(void) {
    static char *text;
    SDL_free(text);
    text = SDL_GetClipboardText();
    return text ? text : "";
}
void sr_clipboard_set(const char *text) { SDL_SetClipboardText(text); }
void sr_window_minimize(void) {
    if (window)
        SDL_MinimizeWindow(window);
}
