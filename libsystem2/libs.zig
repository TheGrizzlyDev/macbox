const std = @import("std");
const system = std.os.system;

const c = @cImport({
    @cInclude("unistd.h");
});

const RTLD_NEXT = @as(*anyopaque, @ptrFromInt(@as(usize, @bitCast(@as(isize, @as(c_int, -1))))));

pub const DlError = error{SymbolNotFound};

fn next_fn(name: [*:0]const u8, signature: anytype) !*@TypeOf(signature) {
    // TODO: cache previously fetched functions
    if (@call(.never_tail, system.dlsym, .{ RTLD_NEXT, name })) |func| {
        return @as(*@TypeOf(c.getcwd), @ptrCast(@alignCast(func)));
    } else {
        return DlError.SymbolNotFound;
    }
}

pub const libc = struct {
    pub fn getcwd(buf: [*]u8, len: usize) ![*]u8 {
        return @call(.never_tail, try next_fn("getcwd", c.getcwd), .{ buf, len });
    }

    pub fn close(fd: c_int) !c_int {
        return @call(.never_tail, try next_fn("close", c.close), .{fd});
    }

    pub fn connect(fd: c_int, addr: *c.sockaddr, len: c.socklen_t) c_int {
        return @call(.never_tail, try next_fn("connect", c.connect), .{ fd, addr, len });
    }

    // LazyFn<pid_t> getpid = {"getpid"};
    // LazyFn<pid_t> gettid = {"gettid"};
    // LazyFn<size_t> malloc = {"malloc"};
    // LazyFn<ssize_t, int, void*, size_t> read = {"read"};
    // LazyFn<long, long, void*> syscall = {"syscall"};
    // LazyFn<int, int, int, int> socket = {"socket"};
    // LazyFn<ssize_t, int, const void*, size_t> write = {"write"};
    // TODO: add getenv
};
