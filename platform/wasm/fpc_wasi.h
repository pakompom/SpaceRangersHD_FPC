#ifndef FPC_EMSCRIPTEN_WASI_H
#define FPC_EMSCRIPTEN_WASI_H

#ifdef __cplusplus
extern "C" {
#endif

/* Call from the application pthread, before initializing the Pascal RTL. */
int fpc_mount_filesystem(void);
int fpc_wasi_initialize(int argc, char **argv);
void fpc_browser_exit(int code);

#ifdef __cplusplus
}
#endif
#endif
