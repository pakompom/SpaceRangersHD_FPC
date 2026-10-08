// Translate the WASI Preview 1 calls used by FPC to Emscripten's own
// libc/WasmFS. There is one filesystem and one native descriptor table.
// Pascal fd 3 is its root preopen; opened handles are native fd + 4.
#include "fpc_wasi.h"
#include <wasi/api.h>
#include <algorithm>
#include <cerrno>
#include <climits>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <dirent.h>
#include <fcntl.h>
#include <limits>
#include <string>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>
#include <vector>

extern char **environ;
namespace {
int root_fd = -1;
std::vector<std::string> arguments, environment;
constexpr uint32_t descriptor_bias = 4;
int host_fd(__wasi_fd_t fd) {
    if (fd < 3)
        return int(fd);
    if (fd == 3)
        return root_fd;
    if (fd - descriptor_bias > INT_MAX)
        return -1;
    return int(fd - descriptor_bias);
}
__wasi_errno_t result(int rc) { return rc < 0 ? errno : 0; }
std::string path_string(const char *path, size_t length) { return std::string(path, length); }
bool valid_path(const char *path, size_t length) { return !memchr(path, 0, length); }
__wasi_errno_t sizes(const std::vector<std::string> &strings, __wasi_size_t *count,
                     __wasi_size_t *bytes) {
    *count = strings.size();
    *bytes = 0;
    for (const auto &item : strings)
        *bytes += item.size() + 1;
    return 0;
}
__wasi_errno_t copy_strings(const std::vector<std::string> &strings, uint8_t **pointers,
                            uint8_t *bytes) {
    for (const auto &item : strings) {
        *pointers++ = bytes;
        memcpy(bytes, item.c_str(), item.size() + 1);
        bytes += item.size() + 1;
    }
    return 0;
}
__wasi_filetype_t file_type(mode_t mode) {
    if (S_ISREG(mode))
        return __WASI_FILETYPE_REGULAR_FILE;
    if (S_ISDIR(mode))
        return __WASI_FILETYPE_DIRECTORY;
    if (S_ISLNK(mode))
        return __WASI_FILETYPE_SYMBOLIC_LINK;
    if (S_ISCHR(mode))
        return __WASI_FILETYPE_CHARACTER_DEVICE;
    if (S_ISBLK(mode))
        return __WASI_FILETYPE_BLOCK_DEVICE;
    if (S_ISSOCK(mode))
        return __WASI_FILETYPE_SOCKET_STREAM;
    return __WASI_FILETYPE_UNKNOWN;
}
uint64_t timestamp(const timespec &value) {
    return uint64_t(value.tv_sec) * 1000000000ULL + value.tv_nsec;
}
void stat_result(const struct stat &source, __wasi_filestat_t *dest) {
    *dest = {};
    dest->dev = source.st_dev;
    dest->ino = source.st_ino;
    dest->filetype = file_type(source.st_mode);
    dest->nlink = source.st_nlink;
    dest->size = source.st_size;
    dest->atim = timestamp(source.st_atim);
    dest->mtim = timestamp(source.st_mtim);
    dest->ctim = timestamp(source.st_ctim);
}
void set_times(timespec (&out)[2], uint64_t atime, uint64_t mtime, uint16_t flags) {
    out[0] = {time_t(atime / 1000000000ULL), long(atime % 1000000000ULL)};
    out[1] = {time_t(mtime / 1000000000ULL), long(mtime % 1000000000ULL)};
    if (flags & __WASI_FSTFLAGS_ATIM_NOW)
        out[0].tv_nsec = UTIME_NOW;
    else if (!(flags & __WASI_FSTFLAGS_ATIM))
        out[0].tv_nsec = UTIME_OMIT;
    if (flags & __WASI_FSTFLAGS_MTIM_NOW)
        out[1].tv_nsec = UTIME_NOW;
    else if (!(flags & __WASI_FSTFLAGS_MTIM))
        out[1].tv_nsec = UTIME_OMIT;
}
clockid_t clock_id(__wasi_clockid_t id) {
    switch (id) {
    case __WASI_CLOCKID_REALTIME:
        return CLOCK_REALTIME;
    case __WASI_CLOCKID_MONOTONIC:
        return CLOCK_MONOTONIC;
    case __WASI_CLOCKID_PROCESS_CPUTIME_ID:
        return CLOCK_PROCESS_CPUTIME_ID;
    case __WASI_CLOCKID_THREAD_CPUTIME_ID:
        return CLOCK_THREAD_CPUTIME_ID;
    default:
        return clockid_t(-1);
    }
}
} // namespace

extern "C" {
int fpc_wasi_initialize(int argc, char **argv) {
    if (root_fd >= 0)
        return EALREADY;
    root_fd = open("/", O_RDONLY | O_DIRECTORY);
    if (root_fd < 0)
        return errno;
    for (int i = 0; i < argc; ++i)
        arguments.emplace_back(argv[i]);
    for (char **p = environ; p && *p; ++p)
        environment.emplace_back(*p);
    return 0;
}
__wasi_errno_t args_sizes_get(__wasi_size_t *n, __wasi_size_t *bytes) {
    return sizes(arguments, n, bytes);
}
__wasi_errno_t args_get(uint8_t **pointers, uint8_t *bytes) {
    return copy_strings(arguments, pointers, bytes);
}
__wasi_errno_t environ_sizes_get(__wasi_size_t *n, __wasi_size_t *bytes) {
    return sizes(environment, n, bytes);
}
__wasi_errno_t environ_get(uint8_t **pointers, uint8_t *bytes) {
    return copy_strings(environment, pointers, bytes);
}
__wasi_errno_t fd_prestat_get(__wasi_fd_t fd, __wasi_prestat_t *out) {
    if (fd != 3 || root_fd < 0)
        return __WASI_ERRNO_BADF;
    *out = {};
    out->pr_type = __WASI_PREOPENTYPE_DIR;
    out->u.dir.pr_name_len = 1;
    return 0;
}
__wasi_errno_t fd_prestat_dir_name(__wasi_fd_t fd, char *out, size_t length) {
    if (fd != 3 || root_fd < 0)
        return __WASI_ERRNO_BADF;
    if (length < 1)
        return __WASI_ERRNO_NAMETOOLONG;
    out[0] = '/';
    return 0;
}
__wasi_errno_t fd_read(__wasi_fd_t fd, const __wasi_iovec_t *iov, size_t n, __wasi_size_t *read) {
    return __wasi_fd_read(host_fd(fd), iov, n, read);
}
__wasi_errno_t fd_write(__wasi_fd_t fd, const __wasi_ciovec_t *iov, size_t n,
                        __wasi_size_t *written) {
    return __wasi_fd_write(host_fd(fd), iov, n, written);
}
__wasi_errno_t fd_pread(__wasi_fd_t fd, const __wasi_iovec_t *iov, size_t n, uint64_t offset,
                        __wasi_size_t *read) {
    return __wasi_fd_pread(host_fd(fd), iov, n, offset, read);
}
__wasi_errno_t fd_pwrite(__wasi_fd_t fd, const __wasi_ciovec_t *iov, size_t n, uint64_t offset,
                         __wasi_size_t *written) {
    return __wasi_fd_pwrite(host_fd(fd), iov, n, offset, written);
}
__wasi_errno_t fd_close(__wasi_fd_t fd) {
    if (fd == 3)
        return __WASI_ERRNO_NOTCAPABLE;
    return __wasi_fd_close(host_fd(fd));
}
__wasi_errno_t fd_seek(__wasi_fd_t fd, int64_t offset, __wasi_whence_t whence, uint64_t *out) {
    return __wasi_fd_seek(host_fd(fd), offset, whence, out);
}
__wasi_errno_t fd_tell(__wasi_fd_t fd, uint64_t *out) {
    return fd_seek(fd, 0, __WASI_WHENCE_CUR, out);
}
__wasi_errno_t fd_sync(__wasi_fd_t fd) { return __wasi_fd_sync(host_fd(fd)); }
__wasi_errno_t fd_datasync(__wasi_fd_t fd) { return result(fdatasync(host_fd(fd))); }
__wasi_errno_t fd_fdstat_get(__wasi_fd_t fd, __wasi_fdstat_t *out) {
    struct stat info;
    if (fstat(host_fd(fd), &info))
        return errno;
    int flags = fcntl(host_fd(fd), F_GETFL);
    if (flags < 0)
        return errno;
    *out = {};
    out->fs_filetype = file_type(info.st_mode);
    if (flags & O_APPEND)
        out->fs_flags |= __WASI_FDFLAGS_APPEND;
    if (flags & O_NONBLOCK)
        out->fs_flags |= __WASI_FDFLAGS_NONBLOCK;
    out->fs_rights_base = out->fs_rights_inheriting = UINT64_MAX;
    return 0;
}
__wasi_errno_t fd_filestat_get(__wasi_fd_t fd, __wasi_filestat_t *out) {
    struct stat info;
    if (fstat(host_fd(fd), &info))
        return errno;
    stat_result(info, out);
    return 0;
}
__wasi_errno_t fd_filestat_set_size(__wasi_fd_t fd, uint64_t size) {
    if (size > INT64_MAX)
        return __WASI_ERRNO_FBIG;
    return result(ftruncate(host_fd(fd), off_t(size)));
}
__wasi_errno_t fd_filestat_set_times(__wasi_fd_t fd, uint64_t atime, uint64_t mtime,
                                     uint16_t flags) {
    timespec times[2];
    set_times(times, atime, mtime, flags);
    return result(futimens(host_fd(fd), times));
}
__wasi_errno_t path_open(__wasi_fd_t fd, uint32_t lookup, const char *path, size_t length,
                         uint16_t oflags, uint64_t rights, uint64_t inheriting, uint16_t fdflags,
                         __wasi_fd_t *out) {
    (void)inheriting;
    if (!valid_path(path, length))
        return __WASI_ERRNO_INVAL;
    bool read = rights & __WASI_RIGHTS_FD_READ;
    bool write = rights & __WASI_RIGHTS_FD_WRITE;
    int flags = write ? (read ? O_RDWR : O_WRONLY) : O_RDONLY;
    if (oflags & __WASI_OFLAGS_CREAT)
        flags |= O_CREAT;
    if (oflags & __WASI_OFLAGS_DIRECTORY)
        flags |= O_DIRECTORY;
    if (oflags & __WASI_OFLAGS_EXCL)
        flags |= O_EXCL;
    if (oflags & __WASI_OFLAGS_TRUNC)
        flags |= O_TRUNC;
    if (fdflags & __WASI_FDFLAGS_APPEND)
        flags |= O_APPEND;
    if (fdflags & __WASI_FDFLAGS_NONBLOCK)
        flags |= O_NONBLOCK;
    if (fdflags & __WASI_FDFLAGS_DSYNC)
        flags |= O_DSYNC;
    if (fdflags & (__WASI_FDFLAGS_RSYNC | __WASI_FDFLAGS_SYNC))
        flags |= O_SYNC;
    if (!(lookup & __WASI_LOOKUPFLAGS_SYMLINK_FOLLOW))
        flags |= O_NOFOLLOW;
    int opened = openat(host_fd(fd), path_string(path, length).c_str(), flags, 0666);
    if (opened < 0)
        return errno;
    *out = opened + descriptor_bias;
    return 0;
}
__wasi_errno_t path_filestat_get(__wasi_fd_t fd, uint32_t lookup, const char *path, size_t length,
                                 __wasi_filestat_t *out) {
    if (!valid_path(path, length))
        return __WASI_ERRNO_INVAL;
    struct stat info;
    int flags = lookup & __WASI_LOOKUPFLAGS_SYMLINK_FOLLOW ? 0 : AT_SYMLINK_NOFOLLOW;
    if (fstatat(host_fd(fd), path_string(path, length).c_str(), &info, flags))
        return errno;
    stat_result(info, out);
    return 0;
}
__wasi_errno_t path_filestat_set_times(__wasi_fd_t fd, uint32_t lookup, const char *path,
                                       size_t length, uint64_t atime, uint64_t mtime,
                                       uint16_t flags) {
    if (!valid_path(path, length))
        return __WASI_ERRNO_INVAL;
    timespec times[2];
    set_times(times, atime, mtime, flags);
    return result(utimensat(host_fd(fd), path_string(path, length).c_str(), times,
                            lookup & __WASI_LOOKUPFLAGS_SYMLINK_FOLLOW ? 0 : AT_SYMLINK_NOFOLLOW));
}
__wasi_errno_t path_create_directory(__wasi_fd_t fd, const char *path, size_t length) {
    if (!valid_path(path, length))
        return __WASI_ERRNO_INVAL;
    return result(mkdirat(host_fd(fd), path_string(path, length).c_str(), 0777));
}
__wasi_errno_t path_unlink_file(__wasi_fd_t fd, const char *path, size_t length) {
    if (!valid_path(path, length))
        return __WASI_ERRNO_INVAL;
    return result(unlinkat(host_fd(fd), path_string(path, length).c_str(), 0));
}
__wasi_errno_t path_remove_directory(__wasi_fd_t fd, const char *path, size_t length) {
    if (!valid_path(path, length))
        return __WASI_ERRNO_INVAL;
    return result(unlinkat(host_fd(fd), path_string(path, length).c_str(), AT_REMOVEDIR));
}
__wasi_errno_t path_rename(__wasi_fd_t oldfd, const char *oldpath, size_t oldlen, __wasi_fd_t newfd,
                           const char *newpath, size_t newlen) {
    if (!valid_path(oldpath, oldlen) || !valid_path(newpath, newlen))
        return __WASI_ERRNO_INVAL;
    return result(renameat(host_fd(oldfd), path_string(oldpath, oldlen).c_str(), host_fd(newfd),
                           path_string(newpath, newlen).c_str()));
}
__wasi_errno_t path_readlink(__wasi_fd_t fd, const char *path, size_t length, char *buf,
                             size_t size, __wasi_size_t *used) {
    if (!valid_path(path, length))
        return __WASI_ERRNO_INVAL;
    ssize_t count = readlinkat(host_fd(fd), path_string(path, length).c_str(), buf, size);
    if (count < 0)
        return errno;
    *used = count;
    return 0;
}
__wasi_errno_t fd_readdir(__wasi_fd_t fd, uint8_t *buffer, size_t size, uint64_t cookie,
                          __wasi_size_t *used) {
    *used = 0;
    if (cookie > LONG_MAX)
        return __WASI_ERRNO_INVAL;
    int duplicate = dup(host_fd(fd));
    if (duplicate < 0)
        return errno;
    DIR *directory = fdopendir(duplicate);
    if (!directory) {
        int error = errno;
        close(duplicate);
        return error;
    }
    errno = 0;
    seekdir(directory, long(cookie));
    if (errno) {
        int error = errno;
        closedir(directory);
        return error;
    }
    __wasi_errno_t error = 0;
    while (*used < size) {
        errno = 0;
        dirent *entry = readdir(directory);
        if (!entry) {
            error = errno;
            break;
        }
        __wasi_dirent_t record = {};
        record.d_next = telldir(directory);
        record.d_ino = entry->d_ino;
        record.d_namlen = strlen(entry->d_name);
        switch (entry->d_type) {
        case DT_DIR:
            record.d_type = __WASI_FILETYPE_DIRECTORY;
            break;
        case DT_REG:
            record.d_type = __WASI_FILETYPE_REGULAR_FILE;
            break;
        case DT_LNK:
            record.d_type = __WASI_FILETYPE_SYMBOLIC_LINK;
            break;
        default:
            record.d_type = __WASI_FILETYPE_UNKNOWN;
        }
        size_t head = std::min(size - *used, sizeof(record));
        memcpy(buffer + *used, &record, head);
        *used += head;
        if (head < sizeof(record))
            break;
        size_t tail = std::min(size - *used, size_t(record.d_namlen));
        memcpy(buffer + *used, entry->d_name, tail);
        *used += tail;
        if (tail < record.d_namlen)
            break;
    }
    closedir(directory);
    return error;
}
__wasi_errno_t clock_time_get(__wasi_clockid_t id, uint64_t precision, uint64_t *out) {
    (void)precision;
    timespec value;
    if (clock_gettime(clock_id(id), &value))
        return errno;
    *out = timestamp(value);
    return 0;
}
__wasi_errno_t clock_res_get(__wasi_clockid_t id, uint64_t *out) {
    timespec value;
    if (clock_getres(clock_id(id), &value))
        return errno;
    *out = timestamp(value);
    return 0;
}
__wasi_errno_t random_get(void *buffer, size_t length) {
    auto *bytes = static_cast<uint8_t *>(buffer);
    while (length) {
        size_t count = std::min(length, size_t(256));
        if (getentropy(bytes, count))
            return errno;
        bytes += count;
        length -= count;
    }
    return 0;
}
__wasi_errno_t poll_oneoff(const __wasi_subscription_t *subscriptions, __wasi_event_t *events,
                           size_t count, __wasi_size_t *nevents) {
    if (!count)
        return __WASI_ERRNO_INVAL;
    // FPC uses Preview 1 polling for Sleep. Reject unsupported descriptor
    // polling explicitly rather than claiming an event has occurred.
    uint64_t delay = UINT64_MAX;
    std::vector<uint64_t> delays(count);
    for (size_t i = 0; i < count; ++i) {
        const auto &sub = subscriptions[i];
        if (sub.type != __WASI_EVENTTYPE_CLOCK)
            return __WASI_ERRNO_NOTSUP;
        if (clock_id(sub.u.clock.id) == clockid_t(-1))
            return __WASI_ERRNO_INVAL;
        uint64_t wait = sub.u.clock.timeout;
        if (sub.u.clock.flags & __WASI_SUBCLOCKFLAGS_SUBSCRIPTION_CLOCK_ABSTIME) {
            uint64_t now;
            auto error = clock_time_get(sub.u.clock.id, 0, &now);
            if (error)
                return error;
            wait = wait > now ? wait - now : 0;
        }
        delays[i] = wait;
        delay = std::min(delay, wait);
    }
    timespec remaining = {time_t(delay / 1000000000ULL), long(delay % 1000000000ULL)};
    while (nanosleep(&remaining, &remaining))
        if (errno != EINTR)
            return errno;
    *nevents = 0;
    for (size_t i = 0; i < count; ++i)
        if (delays[i] <= delay) {
            auto &event = events[(*nevents)++];
            event = {};
            event.userdata = subscriptions[i].userdata;
            event.type = __WASI_EVENTTYPE_CLOCK;
        }
    return 0;
}
__attribute__((noreturn)) void proc_exit(uint32_t code) {
    fpc_browser_exit(int(code));
    exit(int(code));
}
}
