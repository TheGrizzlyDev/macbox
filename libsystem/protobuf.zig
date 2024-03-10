const std = @import("std");
const proto = @cImport({
    @cInclude("proto/macbox/core/v1/macbox.upb.h");
});

const ProtobufErrors = error{
    failed_allocation,
    failed_parsing,
};

const ArenaCreationError = error{
    failed_to_create,
};

fn upb_string_view_to_string(u: proto.upb_StringView) ?[]const u8 {
    if (u.data) |str| {
        return str[0..u.size];
    }
    return null;
}

fn upb_string_view_from_string(s: []const u8) proto.upb_StringView {
    return .{
        .size = s.len,
        .data = s.ptr,
    };
}

pub fn new_arena() ?*proto.upb_Arena {
    // TODO: will need to be removed in favour of an allocator that uses the next occurrence of malloc
    // as soon as we override malloc
    return proto.upb_Arena_New();
}

const AllocatorBackedUpbArena = extern struct {
    const Self = @This();
    func: *const anyopaque,
    allocator: *const std.mem.Allocator,
    arena: *proto.upb_Arena,

    pub fn init(alloc: *const std.mem.Allocator) !*Self {
        var self = try alloc.create(AllocatorBackedUpbArena);
        errdefer alloc.destroy(self);
        self.allocator = alloc;
        self.func = &AllocatorBackedUpbArena.upbAllocFunc;

        if (proto.upb_Arena_Init(null, 0, @ptrCast(self))) |arena| {
            self.arena = arena;
        } else {
            return ArenaCreationError.failed_to_create;
        }

        return self;
    }

    pub fn deinit(self: *Self) void {
        proto.upb_Arena_Free(self.arena);
        self.allocator.destroy(self);
    }

    pub export fn upbAllocFunc(self: *Self, ptr: [*c]u8, old_size: usize, size: usize) [*c]u8 {
        std.debug.print("(ptr='{*}', old_size={}, size={})\n", .{ ptr, old_size, size });
        if (ptr == null) {
            std.debug.print("ALLOC\n", .{});
            const mem = self.allocator.alloc(u8, size) catch return null;
            return mem.ptr;
        }
        // const old_mem: []u8 = &ptr;
        // if (size == 0) {
        //     std.debug.print("FREE\n", .{});
        //     self.allocator.free(old_mem);
        //     return null;
        // }
        // std.debug.print("REALLOC\n", .{});
        // const mem = self.allocator.realloc(old_mem, size) catch return null;
        // return mem.ptr;
    }

    pub fn upbArena(self: *Self) *proto.upb_Arena {
        return self.arena;
    }
};

test "upb uses a zig allocator and does not leak" {
    var arena = try AllocatorBackedUpbArena.init(&std.testing.allocator);
    defer arena.deinit();
    var req = try ApiRequest.init(arena.upbArena());
    req.set_pid(1);
    try std.testing.expectEqual(req.get_pid(), 1);
}

pub const ApiRequest = struct {
    const Self = @This();
    msg: *proto.macbox_core_v1_ApiRequest,
    arena: *proto.upb_Arena,

    pub fn init(arena: *proto.upb_Arena) !Self {
        if (proto.macbox_core_v1_ApiRequest_new(arena)) |msg| {
            return .{ .msg = msg, .arena = arena };
        }
        return ProtobufErrors.failed_allocation;
    }

    pub fn deserialize(arena: *proto.upb_Arena, ser: []const u8) !Self {
        if (proto.macbox_core_v1_ApiRequest_parse(ser.ptr, ser.len, arena)) |msg| {
            return .{ .msg = msg, .arena = arena };
        }
        return ProtobufErrors.failed_allocation;
    }

    pub fn serialize(self: *Self) []const u8 {
        var size: usize = 0;
        const str = proto.macbox_core_v1_ApiRequest_serialize(self.msg, self.arena, &size);

        return str[0..size];
    }

    pub fn set_tid(self: *Self, tid: ?i32) void {
        if (tid) |_tid| {
            proto.macbox_core_v1_ApiRequest_set_tid(self.msg, _tid);
        } else {
            proto.macbox_core_v1_ApiRequest_clear_tid(self.msg);
        }
    }

    pub fn get_tid(self: *Self) i32 {
        return proto.macbox_core_v1_ApiRequest_tid(self.msg);
    }

    pub fn set_pid(self: *Self, pid: ?i32) void {
        if (pid) |_pid| {
            proto.macbox_core_v1_ApiRequest_set_pid(self.msg, _pid);
        } else {
            proto.macbox_core_v1_ApiRequest_clear_pid(self.msg);
        }
    }

    pub fn get_pid(self: *Self) i32 {
        return proto.macbox_core_v1_ApiRequest_pid(self.msg);
    }

    pub fn set_payload(self: *Self, payload: ?[]const u8) void {
        if (payload) |_payload| {
            proto.macbox_core_v1_ApiRequest_set_payload(self.msg, upb_string_view_from_string(_payload));
        } else {
            proto.macbox_core_v1_ApiRequest_clear_payload(
                self.msg,
            );
        }
    }

    pub fn get_payload(self: *Self) ?[]const u8 {
        return upb_string_view_to_string(proto.macbox_core_v1_ApiRequest_payload(self.msg));
    }
};
