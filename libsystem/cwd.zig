const std = @import("std");
const libs = @import("./libs.zig");
const errno = @import("./errno.zig");
const api = @import("./api.zig");
const allocator = @import("./allocator.zig");

export fn getcwd(buf: ?[*]u8, len: usize) ?[*]u8 {
    // const handle = libs.dlsym("getcwd") catch |err| switch (err) {
    //     error.SymbolNotFound => {
    //         errno.set_errno(.AccessPermissionDenied);
    //         return null;
    //     },
    // };
    // return @call(.never_tail, handle, .{ buf, len });

    const cwd: []const u8 = api.getcwd();

    const actual_len = if (buf == null) cwd.len else len;

    // TODO: bad idea, this needs to return memory created with malloc that can be freed using free
    var out: [*]u8 = buf orelse @ptrCast(allocator.get().alloc(u8, cwd.len) catch |err| switch (err) {
        else => {
            // TODO: handle this error better
            errno.set_errno(.AccessPermissionDenied);
            return null;
        },
    });

    for (0..actual_len) |i| {
        if (i >= cwd.len) {
            out[i] = 0;
            break;
        }
        out[i] = cwd[i];
    }
    return out;
}
