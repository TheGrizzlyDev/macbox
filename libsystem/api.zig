const std = @import("std");
const libs = @import("./libs.zig");
const allocator = @import("./allocator.zig");

const c = @cImport({
    @cInclude("libsystem/api.h");
});

const Connection = struct {
    const Self = @This();

    socket: c_int,

    const Error = error{
        CannotOpenSocket,
        CannotConnect,
    };

    pub fn init(socket_path: []const u8) !Self {
        const socket_fn = try libs.dlsym("socket");
        const socket = socket_fn(c.AF_UNIX, c.SOCK_STREAM, 0);
        if (socket == -1) {
            return Error.CannotOpenSocket;
        }

        const addr = c.macbox_create_unix_address(socket_path.ptr, socket_path.len);
        const connect_fn = try libs.dlsym("connect");
        _ = connect_fn(socket, @ptrCast(&addr), @intCast(@sizeOf(c.sockaddr) + socket_path.len)); // do not ignore failures

        return .{ .socket = socket };
    }
};

const Client = struct {
    const Self = @This();
    const ConnectionPoolMap = std.AutoHashMap(i32, Connection);
    connection_pool: ConnectionPoolMap,

    pub fn init() Self {
        return .{ .connection_pool = ConnectionPoolMap.init(allocator.get()) };
    }

    pub fn get_connection(self: *Self) !*Connection {
        const getpid = try libs.dlsym("getpid");
        const pid = getpid();
        return self.connection_pool.getPtr(pid) orelse blk: {
            var conn = try Connection.init("/bla/bla/bla/bla/bla");
            try self.connection_pool.putNoClobber(pid, conn);
            break :blk &conn;
        };
    }
};

var client: ?Client = null;

fn get_client() *Client {
    if (client == null) {
        client = Client.init();
    }
    return &client.?;
}

pub fn getcwd() []const u8 {
    const conn = get_client().get_connection() catch return "";
    _ = conn;
    return "/bla/bla";
}
