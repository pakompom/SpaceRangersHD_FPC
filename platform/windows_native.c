/* Windows host services. Kept apart from game_native.c so <windows.h> never meets
 * jpeglib.h's `boolean` or SDL's declarations in one translation unit. */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <locale.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>

void sr_memory(uint64_t *total, uint64_t *available) {
    MEMORYSTATUSEX status;
    status.dwLength = sizeof(status);
    *total = 0;
    *available = 0;
    if (GlobalMemoryStatusEx(&status)) {
        *total = status.ullTotalPhys;
        *available = status.ullAvailPhys;
    }
}

/* Windows has no libc DLL for the script runtime's external 'c' imports; UCRT
 * supplies the same C99 formatting and locale data. */
int sr_snprintf(char *buffer, size_t size, const char *format, ...) {
    va_list args;
    va_start(args, format);
    int result = vsnprintf(buffer, size, format, args);
    va_end(args);
    return result;
}

struct lconv *sr_localeconv(void) {
    return localeconv();
}
