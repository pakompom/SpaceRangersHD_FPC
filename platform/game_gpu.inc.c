/* Optional GPU implementation of the recovered game's 2D texture/vertex API.
   Included by game_native.c so it shares SDL's window and event coordinates. */
typedef struct SrGpuImage {
    SDL_Texture *texture;
    int width, height, format, target, retired;
    struct SrGpuImage *next;
} SrGpuImage;
static SrGpuImage *gpu_images, *gpu_screen;
static SDL_SpinLock gpu_image_lock;
static int gpu_requested, gpu_active;
static SDL_Rect gpu_clip;
static const void *gpu_cpu_pixels;
static int gpu_cpu_pitch;
static int gpu_flush_software(void);

int sr_renderer_select(int hardware) {
    if (window) {
        SDL_SetError("Select renderer before opening the window");
        return 0;
    }
    gpu_requested = hardware != 0;
    return 1;
}
const char *sr_renderer_name(void) {
    SDL_RendererInfo info;
    if (!renderer)
        return headless ? "headless software" : "uninitialized";
    if (SDL_GetRendererInfo(renderer, &info) < 0)
        return "unknown";
    return info.name;
}
int sr_gpu_active(void) { return gpu_active; }
static Uint32 gpu_format(int format) {
    return format == 23   ? SDL_PIXELFORMAT_RGB565
           : format == 21 ? SDL_PIXELFORMAT_BGRA32
                          : SDL_PIXELFORMAT_UNKNOWN;
}
void *sr_gpu_image_create(int width, int height, int format, int target) {
    if (width <= 0 || height <= 0 || width > 16384 || height > 16384 || !gpu_format(format)) {
        SDL_SetError("Unsupported GPU image size or format");
        return NULL;
    }
    SrGpuImage *image = calloc(1, sizeof(*image));
    if (!image) {
        SDL_OutOfMemory();
        return NULL;
    }
    image->width = width;
    image->height = height;
    image->format = format;
    image->target = target;
    SDL_AtomicLock(&gpu_image_lock);
    image->next = gpu_images;
    gpu_images = image;
    SDL_AtomicUnlock(&gpu_image_lock);
    return image;
}
void sr_gpu_image_free(void *handle) {
    if (!handle)
        return;
    /* Cache destruction may occur off the UI thread. SDL destruction is
       deferred to the rendering thread, including shutdown. */
    SDL_AtomicLock(&gpu_image_lock);
    ((SrGpuImage *)handle)->retired = 1;
    SDL_AtomicUnlock(&gpu_image_lock);
}
static void gpu_collect(int all) {
    SDL_AtomicLock(&gpu_image_lock);
    SrGpuImage **link = &gpu_images;
    while (*link) {
        SrGpuImage *image = *link;
        if (all || image->retired) {
            if (image->texture)
                SDL_DestroyTexture(image->texture);
            image->texture = NULL;
            if (image->retired) {
                *link = image->next;
                free(image);
                continue;
            }
        }
        link = &image->next;
    }
    SDL_AtomicUnlock(&gpu_image_lock);
}
/* Host camera transform. Identity outside the observer's world draw. */
static float gpu_view_scale = 1, gpu_view_x, gpu_view_y;
static SDL_Rect gpu_view_clip;
static int gpu_view_active;
int sr_gpu_view(float scale, float x, float y, int left, int top, int right, int bottom) {
    if (!isfinite(scale) || scale <= 0 || !isfinite(x) || !isfinite(y))
        return SDL_SetError("Invalid camera transform"), 0;
    if (!gpu_flush_software())
        return 0;
    gpu_view_scale = scale;
    gpu_view_x = x;
    gpu_view_y = y;
    gpu_view_active = scale != 1 || x != 0 || y != 0;
    gpu_view_clip = (SDL_Rect){left, top, SDL_max(0, right - left), SDL_max(0, bottom - top)};
    return 1;
}
static SDL_FPoint gpu_view_point(float x, float y) {
    return (SDL_FPoint){x * gpu_view_scale + gpu_view_x, y * gpu_view_scale + gpu_view_y};
}
static int gpu_realize(SrGpuImage *image) {
    if (!image || !gpu_active) {
        SDL_SetError("GPU renderer is not active");
        return 0;
    }
    if (!image->texture) {
        image->texture =
            SDL_CreateTexture(renderer, gpu_format(image->format),
                              image->target ? SDL_TEXTUREACCESS_TARGET : SDL_TEXTUREACCESS_STATIC,
                              image->width, image->height);
        if (!image->texture)
            return 0;
        if (SDL_SetTextureBlendMode(image->texture, SDL_BLENDMODE_BLEND) < 0)
            return 0;
    }
    return 1;
}
int sr_gpu_image_upload(void *handle, const void *pixels, int pitch) {
    SrGpuImage *image = handle;
    if (!image || !pixels || pitch < image->width * (image->format == 23 ? 2 : 4))
        return SDL_SetError("Invalid GPU upload"), 0;
    if (!gpu_realize(image) || SDL_UpdateTexture(image->texture, NULL, pixels, pitch) < 0)
        return 0;

    return 1;
}
static int gpu_bind(SrGpuImage *image) {
    if (!gpu_realize(image) || SDL_SetRenderTarget(renderer, image->texture) < 0)
        return 0;
    /* The render target is in game pixels. Logical/window scaling is only
       applied when copying the finished target to the window. */
    if (SDL_RenderSetLogicalSize(renderer, 0, 0) < 0 || SDL_RenderSetScale(renderer, 1, 1) < 0 ||
        SDL_RenderSetViewport(renderer, NULL) < 0 || SDL_RenderSetClipRect(renderer, &gpu_clip) < 0)
        return 0;
    return 1;
}
int sr_gpu_target(void *handle) {
    return gpu_flush_software() && gpu_bind(handle ? handle : gpu_screen);
}
int sr_gpu_clip(int left, int top, int right, int bottom) {
    if (gpu_view_active) {
        int l = (int)floorf(left * gpu_view_scale + gpu_view_x),
            t = (int)floorf(top * gpu_view_scale + gpu_view_y);
        int r = (int)ceilf(right * gpu_view_scale + gpu_view_x),
            b = (int)ceilf(bottom * gpu_view_scale + gpu_view_y);
        SDL_Rect transformed = {l, t, SDL_max(0, r - l), SDL_max(0, b - t)};
        if (!SDL_IntersectRect(&transformed, &gpu_view_clip, &gpu_clip))
            gpu_clip = (SDL_Rect){0, 0, 0, 0};
    } else
        gpu_clip = (SDL_Rect){left, top, SDL_max(0, right - left), SDL_max(0, bottom - top)};
    return SDL_RenderSetClipRect(renderer, &gpu_clip) == 0;
}
int sr_gpu_clear(uint32_t color) {
    if (!gpu_flush_software())
        return 0;
    if (SDL_SetRenderDrawColor(renderer, color >> 16, color >> 8, color, color >> 24) < 0)
        return 0;
    return SDL_RenderClear(renderer) == 0;
}
int sr_gpu_read(void *handle, void *pixels, int pitch, int format) {
    if (!gpu_flush_software())
        return 0;
    SrGpuImage *image = handle ? handle : gpu_screen;
    if (!image || !pixels || !gpu_format(format) || pitch < image->width * (format == 23 ? 2 : 4))
        return SDL_SetError("Invalid GPU readback"), 0;
    SDL_Texture *previous = SDL_GetRenderTarget(renderer);
    if (!gpu_bind(image))
        return 0;
    int result = SDL_RenderReadPixels(renderer, NULL, gpu_format(format), pixels, pitch);
    if (SDL_SetRenderTarget(renderer, previous) < 0)
        return 0;
    SDL_RenderSetLogicalSize(renderer, 0, 0);
    SDL_RenderSetScale(renderer, 1, 1);
    SDL_RenderSetViewport(renderer, NULL);
    SDL_RenderSetClipRect(renderer, &gpu_clip);

    return result == 0;
}
/* Matches packed TScreenVertexGR / TRotateImageVertexGI, with no pointer ABI. */
typedef struct SrGpuVertex {
    float x, y, z, rhw;
    uint32_t color;
    float u, v;
} SrGpuVertex;
_Static_assert(sizeof(SrGpuVertex) == 28, "vertex ABI");
static SDL_Color gpu_color(uint32_t c) { return (SDL_Color){c >> 16, c >> 8, c, c >> 24}; }
int sr_gpu_draw(void *handle, int kind, int count, const void *data, int stride, int linear,
                int flat) {
    if (!gpu_flush_software())
        return 0;
    if (count <= 0)
        return 1;
    if (!gpu_active || !data || stride != sizeof(SrGpuVertex) || count > 1000000)
        return SDL_SetError("Invalid GPU primitive"), 0;
    SrGpuImage *image = handle;
    if (image && (!gpu_realize(image) ||
                  SDL_SetTextureScaleMode(image->texture, (linear || gpu_view_scale < 1)
                                                              ? SDL_ScaleModeLinear
                                                              : SDL_ScaleModeNearest) < 0))
        return 0;
    if (SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND) < 0)
        return 0;
    const SrGpuVertex *source = data;
    int vertices = kind == 1   ? count
                   : kind == 3 ? count + 1
                   : kind == 4 ? count * 3
                   : kind == 6 ? count + 2
                               : 0;
    if (!vertices)
        return SDL_SetError("Unsupported GPU primitive %d", kind), 0;
    if (kind == 1) {
        for (int i = 0; i < vertices; i++) {
            SDL_Color c = gpu_color(source[i].color);
            SDL_FPoint p = gpu_view_point(source[i].x, source[i].y);
            if (SDL_SetRenderDrawColor(renderer, c.r, c.g, c.b, c.a) < 0 ||
                SDL_RenderDrawPointF(renderer, p.x, p.y) < 0)
                return 0;
        }
    } else if (kind == 3) {
        /* Thin triangles preserve per-endpoint colour/alpha, unlike SDL's
           constant-colour line API. D3D integer coordinates are pixel centres. */
        for (int i = 0; i < count; i++) {
            float dx = source[i + 1].x - source[i].x, dy = source[i + 1].y - source[i].y;
            float length = hypotf(dx, dy);
            if (length == 0)
                continue;
            float ox = -dy / length * 0.5f, oy = dx / length * 0.5f;
            SDL_Color a = gpu_color(source[i].color), b = flat ? a : gpu_color(source[i + 1].color);
            SDL_Vertex v[4] = {
                {{source[i].x + 0.5f + ox, source[i].y + 0.5f + oy}, a, {0, 0}},
                {{source[i].x + 0.5f - ox, source[i].y + 0.5f - oy}, a, {0, 0}},
                {{source[i + 1].x + 0.5f - ox, source[i + 1].y + 0.5f - oy}, b, {0, 0}},
                {{source[i + 1].x + 0.5f + ox, source[i + 1].y + 0.5f + oy}, b, {0, 0}}};
            for (int j = 0; j < 4; j++)
                v[j].position = gpu_view_point(v[j].position.x, v[j].position.y);
            const int indices[] = {0, 1, 2, 0, 2, 3};
            if (SDL_RenderGeometry(renderer, NULL, v, 4, indices, 6) < 0)
                return 0;
        }
    } else {
        SDL_Vertex stack[64], *v = vertices <= 64 ? stack : malloc((size_t)vertices * sizeof(*v));
        if (!v)
            return SDL_OutOfMemory(), 0;
        for (int i = 0; i < vertices; i++) {
            v[i].position = gpu_view_point(source[i].x + 0.5f, source[i].y + 0.5f);
            v[i].color = gpu_color(source[flat ? (kind == 4 ? i / 3 * 3 : 0) : i].color);
            v[i].tex_coord = (SDL_FPoint){source[i].u, source[i].v};
        }
        int result = 0;
        if (kind == 4)
            result =
                SDL_RenderGeometry(renderer, image ? image->texture : NULL, v, vertices, NULL, 0);
        else {
            int stack_indices[192], *indices = count <= 64
                                                   ? stack_indices
                                                   : malloc((size_t)count * 3 * sizeof(*indices));
            if (!indices) {
                if (v != stack)
                    free(v);
                return SDL_OutOfMemory(), 0;
            }
            for (int i = 0; i < count; i++) {
                indices[3 * i] = 0;
                indices[3 * i + 1] = i + 1;
                indices[3 * i + 2] = i + 2;
            }
            result = SDL_RenderGeometry(renderer, image ? image->texture : NULL, v, vertices,
                                        indices, count * 3);
            if (indices != stack_indices)
                free(indices);
        }
        if (v != stack)
            free(v);
        if (result < 0)
            return 0;
    }

    return 1;
}
static int gpu_open(void) {
    SDL_RendererInfo info;
    if (SDL_GetRendererInfo(renderer, &info) < 0)
        return 0;
    if (!(info.flags & SDL_RENDERER_ACCELERATED) || !(info.flags & SDL_RENDERER_TARGETTEXTURE))
        return SDL_SetError("SDL GPU renderer needs acceleration and render targets; use "
                            "--renderer=software"),
               0;
    gpu_active = 1;
    gpu_clip = (SDL_Rect){0, 0, logical_w, logical_h};
    gpu_screen = sr_gpu_image_create(logical_w, logical_h, 21, 1);
    return gpu_screen && sr_gpu_target(NULL) && sr_gpu_clear(0xff000000);
}
int sr_gpu_present(void) {
    if (!gpu_active)
        return SDL_SetError("GPU renderer is not active"), 0;
    if (!gpu_flush_software())
        return 0;
    gpu_collect(0);
    if (gamma_enabled) {
        /* Preserve the software path's exact RGB565 display gamma. Non-default
           gamma currently needs readback; the normal path stays on the GPU. */
        size_t count = (size_t)logical_w * logical_h;
        if (count > gamma_capacity) {
            uint16_t *next = realloc(gamma_pixels, count * sizeof(*next));
            if (!next)
                return SDL_OutOfMemory(), 0;
            gamma_pixels = next;
            gamma_capacity = count;
        }
        if (!sr_gpu_read(NULL, gamma_pixels, logical_w * 2, 23))
            return 0;
        for (size_t i = 0; i < count; i++)
            gamma_pixels[i] = display_gamma[gamma_pixels[i]];
        if (SDL_UpdateTexture(texture, NULL, gamma_pixels, logical_w * 2) < 0)
            return 0;
    }
    if (SDL_SetRenderTarget(renderer, NULL) < 0 ||
        SDL_RenderSetLogicalSize(renderer, logical_w, logical_h) < 0 ||
        SDL_RenderSetClipRect(renderer, NULL) < 0)
        return 0;
    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    if (SDL_RenderClear(renderer) < 0)
        return 0;
    SDL_Texture *frame = gamma_enabled ? texture : gpu_screen->texture;
    if (SDL_SetTextureBlendMode(frame, SDL_BLENDMODE_NONE) < 0 ||
        SDL_RenderCopy(renderer, frame, NULL, NULL) < 0)
        return 0;
    SDL_RenderPresent(renderer);
    presented_frames++;
    return sr_gpu_target(NULL);
}
static int gpu_flush_software(void) {
    if (!gpu_cpu_pixels)
        return 1;
    SDL_Texture *previous = SDL_GetRenderTarget(renderer);
    if (!gpu_bind(gpu_screen) ||
        SDL_UpdateTexture(texture, NULL, gpu_cpu_pixels, gpu_cpu_pitch) < 0)
        return 0;
    SDL_RenderSetClipRect(renderer, NULL);
    if (SDL_SetTextureBlendMode(texture, SDL_BLENDMODE_NONE) < 0 ||
        SDL_RenderCopy(renderer, texture, NULL, NULL) < 0)
        return 0;

    gpu_cpu_pixels = NULL;
    if (SDL_SetRenderTarget(renderer, previous) < 0)
        return 0;
    SDL_RenderSetLogicalSize(renderer, 0, 0);
    SDL_RenderSetScale(renderer, 1, 1);
    SDL_RenderSetViewport(renderer, NULL);
    SDL_RenderSetClipRect(renderer, &gpu_clip);
    return 1;
}
int sr_gpu_software_pixels(void *pixels, int pitch) {
    if (!gpu_cpu_pixels) {
        if (!sr_gpu_read(NULL, pixels, pitch, 23))
            return 0;
        gpu_cpu_pixels = pixels;
        gpu_cpu_pitch = pitch;
    } else if (gpu_cpu_pixels != pixels || gpu_cpu_pitch != pitch) {
        return SDL_SetError("GPU software fallback buffer changed"), 0;
    }
    return 1;
}
static void gpu_close(void) {
    gpu_cpu_pixels = NULL;
    sr_gpu_image_free(gpu_screen);
    gpu_screen = NULL;
    gpu_collect(1);
    gpu_active = 0;
}
