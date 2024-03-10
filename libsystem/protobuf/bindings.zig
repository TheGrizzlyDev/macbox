const std = @import("std");
const arena = @import("arena.zig");
const strings = @import("strings.zig");
const c = @cImport({
    @cInclude("proto/macbox/core/v1/macbox.upb.h");
});

const ProtobufErrors = error{
    CannotAllocate,
    CannotParse,
};

pub const ApiRequest = struct {
    const Self = @This();
    msg: *c.macbox_core_v1_ApiRequest,
    arena: *arena.AllocatorBackedUpbArena,

    pub fn init(allocator: *const std.mem.Allocator) !Self {
        var newArena = try arena.AllocatorBackedUpbArena.init(allocator);
        errdefer newArena.deinit();
        if (c.macbox_core_v1_ApiRequest_new(arena)) |msg| {
            return .{ .msg = msg, .arena = newArena };
        }
        return ProtobufErrors.CannotAllocate;
    }

    pub fn deserialize(allocator: *const std.mem.Allocator, ser: []const u8) ProtobufErrors!Self {
        var newArena = try arena.AllocatorBackedUpbArena.init(allocator);
        errdefer newArena.deinit();
        if (c.macbox_core_v1_ApiRequest_parse(ser.ptr, ser.len, arena)) |msg| {
            return .{ .msg = msg, .arena = newArena };
        }
        return ProtobufErrors.CannotParse;
    }

    pub fn deinit(self: *Self) void {
        self.arena.deinit();
    }

    pub fn serialize(self: *Self) []const u8 {
        var size: usize = 0;
        const str = c.macbox_core_v1_ApiRequest_serialize(self.msg, self.arena, &size);

        return str[0..size];
    }

    pub fn set_tid(self: *Self, tid: ?i32) void {
        if (tid) |_tid| {
            c.macbox_core_v1_ApiRequest_set_tid(self.msg, _tid);
        } else {
            c.macbox_core_v1_ApiRequest_clear_tid(self.msg);
        }
    }

    pub fn get_tid(self: *Self) i32 {
        return c.macbox_core_v1_ApiRequest_tid(self.msg);
    }

    pub fn set_pid(self: *Self, pid: ?i32) void {
        if (pid) |_pid| {
            c.macbox_core_v1_ApiRequest_set_pid(self.msg, _pid);
        } else {
            c.macbox_core_v1_ApiRequest_clear_pid(self.msg);
        }
    }

    pub fn get_pid(self: *Self) i32 {
        return c.macbox_core_v1_ApiRequest_pid(self.msg);
    }

    pub fn set_payload(self: *Self, payload: ?[]const u8) void {
        if (payload) |_payload| {
            c.macbox_core_v1_ApiRequest_set_payload(self.msg, strings.upbStringViewFromString(_payload));
        } else {
            c.macbox_core_v1_ApiRequest_clear_payload(
                self.msg,
            );
        }
    }

    pub fn get_payload(self: *Self) ?[]const u8 {
        return strings.upbStringViewToString(c.macbox_core_v1_ApiRequest_payload(self.msg));
    }
};
