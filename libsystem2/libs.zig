const std = @import("std");
const system = std.os.system;

const c = @cImport({
    @cInclude("unistd.h");
});

const RTLD_NEXT = @as(*anyopaque, @ptrFromInt(@as(usize, @bitCast(@as(isize, @as(c_int, -1))))));

pub const libc = struct {
    pub fn getcwd(buf: [*]u8, len: usize) ?[*]u8 {
        if (@call(.never_tail, system.dlsym, .{ RTLD_NEXT, "getcwd" })) |func| {
            return @call(.never_tail, @as(*@TypeOf(c.getcwd), @ptrCast(@alignCast(func))), .{ buf, len });
        } else {
            return null;
        }
    }
};
