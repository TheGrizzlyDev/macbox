usingnamespace @import("cwd.zig");

fn main() !void {}

test {
    _ = @import("./protobuf/arena.zig");
    _ = @import("./protobuf/bindings.zig");
}
