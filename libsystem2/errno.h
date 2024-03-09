#include <errno.h>

// Based on: https://github.com/ziglang/zig/issues/274#issuecomment-288518836
inline static int macbox_get_errno() { return errno; }
inline static void macbox_set_errno(int value) { errno = value; }