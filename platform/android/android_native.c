#include <SDL2/SDL.h>
#include <jni.h>
#include <stdatomic.h>
#include <stdint.h>
#include <time.h>
static atomic_int keys[256];
static atomic_int right_click;
static atomic_int hover_only;
/* UTF-16 avoids JNI's modified-UTF-8 rules for Unicode filesystem names. */
int sr_android_open_document(const uint16_t *path, int length) {
    JNIEnv *env = SDL_AndroidGetJNIEnv();
    jobject activity = SDL_AndroidGetActivity();
    if (!env || !activity)
        return 0;
    jclass cls = (*env)->GetObjectClass(env, activity);
    jmethodID method = (*env)->GetMethodID(env, cls, "openDocument", "(Ljava/lang/String;)Z");
    jstring name = (*env)->NewString(env, (const jchar *)path, length);
    int opened = 0;
    if (method && name)
        opened = (*env)->CallBooleanMethod(env, activity, method, name);
    if ((*env)->ExceptionCheck(env)) {
        (*env)->ExceptionDescribe(env);
        (*env)->ExceptionClear(env);
        opened = 0;
    }
    if (name)
        (*env)->DeleteLocalRef(env, name);
    (*env)->DeleteLocalRef(env, cls);
    (*env)->DeleteLocalRef(env, activity);
    return opened;
}
int sr_android_key(int key) { return key >= 0 && key < 256 ? atomic_load(&keys[key]) : 0; }
int sr_android_right(void) { return atomic_load(&right_click); }
int sr_android_hover(void) { return atomic_load(&hover_only); }
JNIEXPORT void JNICALL Java_org_spacerangershd_android_GameActivity_nativeKey(JNIEnv *env,
                                                                              jclass cls, jint key,
                                                                              jboolean down) {
    (void)env;
    (void)cls;
    if (key < 0 || key >= 256)
        return;
    if (atomic_exchange(&keys[key], down) == down)
        return;
    SDL_Event event;
    SDL_zero(event);
    event.type = SDL_USEREVENT;
    event.user.code = down ? 0x100 : 0x101;
    event.user.data1 = (void *)(intptr_t)key;
    SDL_PushEvent(&event);
}
JNIEXPORT void JNICALL Java_org_spacerangershd_android_GameActivity_nativeRight(JNIEnv *env,
                                                                                jclass cls,
                                                                                jboolean right) {
    (void)env;
    (void)cls;
    atomic_store(&right_click, right);
}
JNIEXPORT void JNICALL Java_org_spacerangershd_android_GameActivity_nativeHover(JNIEnv *env,
                                                                                jclass cls,
                                                                                jboolean hover) {
    (void)env;
    (void)cls;
    atomic_store(&hover_only, hover);
}
JNIEXPORT void JNICALL Java_org_spacerangershd_android_GameActivity_nativeWheel(JNIEnv *env,
                                                                                jclass cls,
                                                                                jint delta) {
    (void)env;
    (void)cls;
    SDL_Event event;
    SDL_zero(event);
    event.type = SDL_MOUSEWHEEL;
    event.wheel.y = delta;
    event.wheel.preciseY = (float)delta;
    SDL_GetMouseState(&event.wheel.mouseX, &event.wheel.mouseY);
    SDL_PushEvent(&event);
}
