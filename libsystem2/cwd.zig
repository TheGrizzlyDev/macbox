const libs = @import("./libs.zig");
const api = @import("./api.zig");
const protobuf = @import("./protobuf.zig");
const errno = @import("./errno.zig");

export fn getcwd(buf: [*]u8, len: usize) ?[*]u8 {
    const handle = libs.dlsym("getcwd") catch |err| switch (err) {
        error.SymbolNotFound => {
            errno.set_errno(.AccessPermissionDenied);
            return null;
        },
    };
    return @call(.never_tail, handle, .{ buf, len });
}
