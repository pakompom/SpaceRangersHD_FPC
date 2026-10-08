// FPC's thread manager uses the Emscripten pthread implementation. TLS storage
// is emitted by LLVM and initialized by Emscripten before a thread starts.
#include <pthread.h>
#include <emscripten/stack.h>
#include <emscripten/threading.h>
#include <errno.h>
#include <stdint.h>
#include <stdlib.h>
#include <atomic>
#include <new>
#include <sched.h>
#include <time.h>

extern "C" {
void sr_fpc_cleanup_thread(void);
static pthread_key_t pascal_key;
static pthread_once_t pascal_once = PTHREAD_ONCE_INIT;
static void cleanup_pascal(void *value) {
    if (value == (void *)1)
        sr_fpc_cleanup_thread();
}
static void create_pascal_key(void) {
    if (pthread_key_create(&pascal_key, cleanup_pascal))
        abort();
}
void sr_fpc_thread_mark(int cleanup) {
    pthread_once(&pascal_once, create_pascal_key);
    if (pthread_setspecific(pascal_key, (void *)(uintptr_t)(cleanup ? 1 : 2)))
        abort();
}
void sr_fpc_thread_unmark(void) { pthread_setspecific(pascal_key, NULL); }
uintptr_t sr_fpc_stack_low(void) { return emscripten_stack_get_end(); }
uintptr_t sr_fpc_stack_high(void) { return emscripten_stack_get_base(); }

struct fpc_thread {
    pthread_t thread;
    pthread_mutex_t mutex;
    pthread_cond_t condition;
    std::atomic_uint references;
    int managed, finished, joined, joining, detached;
    uintptr_t result;
    void *(*entry)(void *);
    void *argument;
};
static thread_local struct fpc_thread *current_thread;
static thread_local struct fpc_thread foreign_thread;
static void release_thread(struct fpc_thread *thread) {
    if (thread->references.fetch_sub(1) == 1) {
        pthread_cond_destroy(&thread->condition);
        pthread_mutex_destroy(&thread->mutex);
        delete thread;
    }
}
static void complete_thread(uintptr_t result) {
    struct fpc_thread *thread = current_thread;
    if (!thread)
        return;
    pthread_mutex_lock(&thread->mutex);
    thread->result = result;
    thread->finished = 1;
    pthread_cond_broadcast(&thread->condition);
    pthread_mutex_unlock(&thread->mutex);
    current_thread = NULL;
    release_thread(thread);
}
static void *thread_main(void *argument) {
    auto *thread = static_cast<fpc_thread *>(argument);
    current_thread = thread;
    void *result = thread->entry(thread->argument);
    complete_thread((uintptr_t)result);
    return result;
}
void *sr_fpc_thread_begin(void *(*entry)(void *), void *argument, uintptr_t size) {
    auto *thread = new (std::nothrow) fpc_thread{};
    if (!thread)
        return NULL;
    thread->entry = entry;
    thread->argument = argument;
    thread->managed = 1;
    thread->references.store(2); // caller's handle and running worker
    if (pthread_mutex_init(&thread->mutex, NULL)) {
        delete thread;
        return NULL;
    }
    if (pthread_cond_init(&thread->condition, NULL)) {
        pthread_mutex_destroy(&thread->mutex);
        delete thread;
        return NULL;
    }
    pthread_attr_t attributes;
    pthread_attr_init(&attributes);
    int error = size ? pthread_attr_setstacksize(&attributes, size) : 0;
    if (!error)
        error = pthread_create(&thread->thread, &attributes, thread_main, thread);
    pthread_attr_destroy(&attributes);
    if (error) {
        release_thread(thread);
        release_thread(thread);
        return NULL;
    }
    return thread;
}
void *sr_fpc_thread_self(void) {
    if (current_thread)
        return current_thread;
    foreign_thread.thread = pthread_self();
    return &foreign_thread;
}
[[noreturn]] void sr_fpc_thread_exit(uint32_t code) {
    complete_thread(code);
    pthread_exit((void *)(uintptr_t)code);
}
static struct timespec deadline(uint32_t milliseconds) {
    struct timespec until;
    clock_gettime(CLOCK_REALTIME, &until);
    until.tv_sec += milliseconds / 1000;
    until.tv_nsec += (milliseconds % 1000) * 1000000L;
    if (until.tv_nsec >= 1000000000L) {
        ++until.tv_sec;
        until.tv_nsec -= 1000000000L;
    }
    return until;
}
uint32_t sr_fpc_thread_wait(struct fpc_thread *thread, int32_t milliseconds) {
    if (!thread || !thread->managed || thread == current_thread)
        return UINT32_MAX;
    thread->references.fetch_add(1);
    struct timespec until = deadline(milliseconds > 0 ? milliseconds : 0);
    pthread_mutex_lock(&thread->mutex);
    int error = 0;
    while (!thread->finished && !error)
        error = milliseconds <= 0
                    ? pthread_cond_wait(&thread->condition, &thread->mutex)
                    : pthread_cond_timedwait(&thread->condition, &thread->mutex, &until);
    if (!error && !thread->detached) {
        while (thread->joining)
            pthread_cond_wait(&thread->condition, &thread->mutex);
        if (!thread->joined) {
            thread->joining = 1;
            pthread_mutex_unlock(&thread->mutex);
            error = pthread_join(thread->thread, NULL);
            pthread_mutex_lock(&thread->mutex);
            thread->joining = 0;
            thread->joined = !error;
            pthread_cond_broadcast(&thread->condition);
        }
    }
    uint32_t result = error ? UINT32_MAX : (uint32_t)thread->result;
    pthread_mutex_unlock(&thread->mutex);
    release_thread(thread);
    return result;
}
uint32_t sr_fpc_thread_close(struct fpc_thread *thread) {
    if (!thread || !thread->managed)
        return UINT32_MAX;
    pthread_mutex_lock(&thread->mutex);
    if (!thread->joined && !thread->joining && !thread->detached) {
        pthread_detach(thread->thread);
        thread->detached = 1;
    }
    pthread_mutex_unlock(&thread->mutex);
    release_thread(thread);
    return 0;
}
void sr_fpc_thread_yield(void) { sched_yield(); }
void sr_fpc_thread_name(struct fpc_thread *thread, const char *name) {
    if (thread == (void *)UINTPTR_MAX)
        thread = static_cast<fpc_thread *>(sr_fpc_thread_self());
    if (thread)
        emscripten_set_thread_name(thread->thread, name);
}

void sr_fpc_mutex_init(void **storage) {
    auto *mutex = new (std::nothrow) pthread_mutex_t{};
    if (!mutex)
        abort();
    pthread_mutexattr_t attributes;
    pthread_mutexattr_init(&attributes);
    pthread_mutexattr_settype(&attributes, PTHREAD_MUTEX_RECURSIVE);
    int error = pthread_mutex_init(mutex, &attributes);
    pthread_mutexattr_destroy(&attributes);
    if (error)
        abort();
    *storage = mutex;
}
void sr_fpc_mutex_destroy(void **storage) {
    if (pthread_mutex_destroy(static_cast<pthread_mutex_t *>(*storage)))
        abort();
    delete static_cast<pthread_mutex_t *>(*storage);
    *storage = NULL;
}
void sr_fpc_mutex_lock(void **storage) {
    if (pthread_mutex_lock(static_cast<pthread_mutex_t *>(*storage)))
        abort();
}
void sr_fpc_mutex_unlock(void **storage) {
    if (pthread_mutex_unlock(static_cast<pthread_mutex_t *>(*storage)))
        abort();
}
int sr_fpc_mutex_trylock(void **storage) {
    int result = pthread_mutex_trylock(static_cast<pthread_mutex_t *>(*storage));
    if (result && result != EBUSY)
        abort();
    return result == 0;
}

struct fpc_event {
    pthread_mutex_t mutex;
    pthread_cond_t condition;
    unsigned waiters;
    int manual, signaled, destroying;
};
void *sr_fpc_event_create(int manual, int signaled) {
    auto *event = new (std::nothrow) fpc_event{};
    if (!event)
        return NULL;
    if (pthread_mutex_init(&event->mutex, NULL)) {
        delete event;
        return NULL;
    }
    if (pthread_cond_init(&event->condition, NULL)) {
        pthread_mutex_destroy(&event->mutex);
        delete event;
        return NULL;
    }
    event->manual = manual;
    event->signaled = signaled;
    return event;
}
void sr_fpc_event_destroy(struct fpc_event *event) {
    if (!event)
        return;
    pthread_mutex_lock(&event->mutex);
    event->destroying = 1;
    pthread_cond_broadcast(&event->condition);
    while (event->waiters)
        pthread_cond_wait(&event->condition, &event->mutex);
    pthread_mutex_unlock(&event->mutex);
    pthread_cond_destroy(&event->condition);
    pthread_mutex_destroy(&event->mutex);
    delete event;
}
void sr_fpc_event_set(struct fpc_event *event) {
    pthread_mutex_lock(&event->mutex);
    event->signaled = 1;
    pthread_cond_broadcast(&event->condition);
    pthread_mutex_unlock(&event->mutex);
}
void sr_fpc_event_reset(struct fpc_event *event) {
    pthread_mutex_lock(&event->mutex);
    event->signaled = 0;
    pthread_mutex_unlock(&event->mutex);
}
// FPC TWaitResult: signaled=0, timeout=1, abandoned=2, error=3.
int sr_fpc_event_wait(struct fpc_event *event, uint32_t milliseconds) {
    if (!event)
        return 3;
    struct timespec until = deadline(milliseconds);
    pthread_mutex_lock(&event->mutex);
    ++event->waiters;
    int error = 0;
    while (!event->signaled && !event->destroying && !error)
        error = milliseconds == UINT32_MAX
                    ? pthread_cond_wait(&event->condition, &event->mutex)
                    : pthread_cond_timedwait(&event->condition, &event->mutex, &until);
    int result = event->destroying ? 2 : error == ETIMEDOUT ? 1 : error ? 3 : 0;
    if (!result && !event->manual)
        event->signaled = 0;
    if (--event->waiters == 0 && event->destroying)
        pthread_cond_broadcast(&event->condition);
    pthread_mutex_unlock(&event->mutex);
    return result;
}
} // extern "C"
