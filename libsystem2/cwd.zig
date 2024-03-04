const libs = @import("./libs.zig");
const api = @import("./api.zig");
const protobuf = @import("./protobuf.zig");

export fn getcwd(buf: [*]u8, len: usize) [*]u8 {
    return libs.libc.getcwd(buf, len) orelse @constCast("/nope");
}