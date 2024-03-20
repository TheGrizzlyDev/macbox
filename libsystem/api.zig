const std = @import("std");
const libs = @import("./libs.zig");
const global_allocator = @import("./allocator.zig");
const rpc = @import("protobuf/types.zig");

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

    fn rawSend(self: *Self, req: *rpc.Request) !*rpc.Response {
        const serializedReq = try req.serialize(&self.allocator);
        defer serializedReq.deinit();
        const lenBuf: *[8]u8 = @ptrCast(try self.allocator.alloc(u8, 8)); // TODO could be on the stack
        defer self.allocator.free(lenBuf);
        std.mem.writeInt(u64, lenBuf, serializedReq.slice.len, .Big);
        const write = try libs.dlsym("write");
        _ = write(self.socket, lenBuf.ptr, lenBuf.len); // TODO check bytes written
        _ = write(self.socket, serializedReq.slice.ptr, serializedReq.slice.len); // TODO check bytes written

        const read = try libs.dlsym("read");
        var responseLenBuf: *[8]u8 = @ptrCast(try self.allocator.alloc(u8, 8)); // TODO could be on the stack
        defer self.allocator.free(responseLenBuf);
        _ = read(self.socket, responseLenBuf, 8); // TODO check bytes read
        const responseLen = std.mem.readInt(u64, responseLenBuf, .Big);
        const responseBuf = try self.allocator.alloc(u8, responseLen);
        defer self.allocator.free(responseBuf);
        _ = read(self.socket, responseBuf.ptr, responseLen); // TODO check bytes read
        return try rpc.Response.deserialize(&self.allocator, responseBuf);
    }

    pub fn send(self: *Self, comptime ResponseType: type, method: []const u8, message: anytype) !*ResponseType {
        var request = try rpc.Request.init(&self.allocator);
        defer request.deinit();
        request.setString("method", method);
        var payload = try message.serialize(&self.allocator);
        defer payload.deinit();
        request.setString("payload", payload.slice);
        var rawResponse = try self.rawSend(request);
        return try ResponseType.deserialize(&self.allocator, rawResponse.getString("payload").?); // TODO actually handle null string
    }
};

// TODO replace with an arena allocator and use that internally
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

// TODO create a initFromEnv method in client to encapsulate setup logic and just reistantiate it every time
// optionally create a cache for sockets and maybe connections
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
    var conn = getClient().getConnection() catch return "/foo";
    std.debug.print("oops\n", .{});
    var request = rpc.ApiRequest.init(&global_allocator.get()) catch return "/bar";
    var response = conn.send(rpc.ApiResponse, "cwd", request) catch return "/goo";
    var cwdResponse = rpc.CwdResponse.deserialize(&global_allocator.get(), response.getString("payload") orelse return "/woo") catch return "/baz";
    return cwdResponse.getString("path") orelse "/yoo";
}
