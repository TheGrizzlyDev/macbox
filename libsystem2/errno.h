#include <errno.h>

// Based on: https://github.com/ziglang/zig/issues/274#issuecomment-288518836
inline static int get_errno() { return errno; }
inline static void set_errno(int value) { errno = value; }