const std = @import("std");
const libs = @import("libs");
const allocator = @import("./allocator.zig");

const Connection = struct {
    pub fn send() void {}
};

const Client = struct {
    const Self = @This();
    const ConnectionPoolMap = std.AutoHashMap(i32, *Connection);
    connection_pool: ConnectionPoolMap = ConnectionPoolMap.init(allocator.get()),
    pub fn get_connection(self: *Self) !*Connection {
        const getpid = try libs.dlsym("getpid");
        return try self.connection_pool.getOrPutValue(getpid(), &Connection{});
    }
};

var client: ?*Client = null;
fn get_client() *Client {
    if (client == null) {
        client = &Client{};
    }
    return client;
}

pub fn getcwd() []const u8 {
    return "/bla/bla";
}
