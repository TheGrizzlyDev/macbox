const std = @import("std");
const libs = @import("./libs.zig");
const global_allocator = @import("./allocator.zig");

const c = @cImport({
    @cInclude("libsystem/api.h");
});

const Connection = struct {
    const Self = @This();

    socket: c_int,
    allocator: std.mem.Allocator,

    const Error = error{
        CannotOpenSocket,
        CannotConnect,
    };

    pub fn init(allocator: std.mem.Allocator, socket_path: []const u8) !*Self {
        const socket_fn = try libs.dlsym("socket");
        const socket = socket_fn(c.AF_UNIX, c.SOCK_STREAM, 0);
        if (socket == -1) {
            return Error.CannotOpenSocket;
        }

        const addr = c.macbox_create_unix_address(socket_path.ptr, socket_path.len);
        const connect_fn = try libs.dlsym("connect");

        if (connect_fn(socket, @ptrCast(&addr), @intCast(@sizeOf(c.sockaddr) + socket_path.len)) == -1) {
            return Error.CannotConnect;
        }

        const self = try allocator.create(Self);
        self.socket = socket;
        self.allocator = allocator;
        return self;
    }

    pub fn deinit(self: *Self) void {
        self.allocator.destroy(self);
    }
};

const Client = struct {
    const Self = @This();
    const ConnectionPoolMap = std.AutoHashMap(i32, *Connection);
    connection_pool: ConnectionPoolMap,
    allocator: std.mem.Allocator,
    socket_path: []const u8,

    pub fn init(allocator: std.mem.Allocator, socket_path: []const u8) !*Self {
        var self = try allocator.create(Self);
        self.connection_pool = ConnectionPoolMap.init(allocator);
        self.allocator = allocator;
        self.socket_path = socket_path;
        return self;
    }

    pub fn getConnection(self: *Self) !*Connection {
        const getpid = try libs.dlsym("getpid");
        const pid = getpid();
        return self.connection_pool.get(pid) orelse blk: {
            var conn = try Connection.init(self.allocator, self.socket_path);
            try self.connection_pool.putNoClobber(pid, conn);
            break :blk conn;
        };
    }
};

var client: ?*Client = null;

fn getClient() *Client {
    if (client == null) {
        const getenv = libs.dlsym("getenv") catch unreachable;
        const c_socket_path = getenv("MACBOX_SANDBOX_SOCKET_PATH") orelse std.debug.panic("env variable 'MACBOX_SANDBOX_SOCKET_PATH' must be set", .{});
        const socket_path: []const u8 = std.mem.span(c_socket_path);
        client = Client.init(global_allocator.get(), socket_path) catch std.debug.panic("could not allocate an API client", .{});
    }
    return client.?;
}

pub fn getcwd() []const u8 {
    var conn = getClient().getConnection() catch return "/";
    _ = conn;
    return "/bla/bla";
}
