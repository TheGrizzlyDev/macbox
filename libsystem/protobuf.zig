const std = @import("std");
const proto = @cImport({
    @cInclude("proto/macbox/core/v1/macbox.upb.h");
});

const allocator = @import("./allocator.zig");

const ProtobufErrors = error{
    failed_allocation,
    failed_parsing,
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

export fn upbAllocFunc(alloc: *anyopaque, ptr: [*c]u8, old_size: usize, size: usize) [*c]u8 {
    _ = alloc;
    if (ptr == null) {
        const mem = allocator.get().alloc(u8, size) catch return null;
        return mem.ptr;
    }
    const old_mem: []u8 = @ptrCast(ptr[0..old_size]);
    if (size == 0) {
        allocator.get().free(old_mem);
        return ptr;
    }
    const mem = allocator.get().realloc(old_mem, size) catch return null;
    return mem.ptr;
}

fn createZigAllocatorBackedArena() ?*proto.upb_Arena {
    var alloc: [*c]proto.upb_alloc = @constCast(&proto.upb_alloc{ .func = @ptrCast(&upbAllocFunc) });
    return proto.upb_Arena_Init(null, 0, alloc);
}

// pub const ProtoField = struct {
//     name: []const u8,
//     typ: type,
// };

// pub fn createProto(fields: []const ProtoField) type {
//     return struct {

//     }
// }

test "upb uses a zig allocator" {
    var arena = createZigAllocatorBackedArena() orelse return std.testing.expect(false);
    var req = try ApiRequest.init(arena);
    std.debug.print("PID: {?}", .{req.get_pid()});
    req.set_pid(1);
    std.debug.print("PID: {?}", .{req.get_pid()});
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
