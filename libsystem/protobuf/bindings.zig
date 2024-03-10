const std = @import("std");
const arena = @import("arena.zig");
const strings = @import("strings.zig");
const c = @cImport({
    @cInclude("proto/macbox/core/v1/macbox.upb.h");
});

const ProtobufErrors = error{
    CannotAllocate,
    CannotParse,
    CannotSerialize,
};

fn SliceWithUpbArena(comptime T: type) type {
    return struct {
        const Self = @This();
        slice: []const T,
        arena: *arena.AllocatorBackedUpbArena,
        alloc: *const std.mem.Allocator,

        pub fn deinit(self: *Self) void {
            self.arena.deinit();
            self.alloc.destroy(self);
        }
    };
}

fn bindToProto(comptime fullyQualifiedName: []const u8) type {
    const upbNamespace: []const u8 = blk: {
        var ns: []const u8 = &[_]u8{};
        for (fullyQualifiedName) |char| {
            if ('.' == char) {
                ns = ns ++ &[_]u8{'_'};
                continue;
            }
            ns = ns ++ &[_]u8{char};
        }
        break :blk ns;
    };

    return struct {
        const Self = @This();
        msg: *@field(c, upbNamespace),
        arena: *arena.AllocatorBackedUpbArena,
        alloc: *const std.mem.Allocator,

        pub fn init(allocator: *const std.mem.Allocator) !*Self {
            var self = try allocator.create(Self);
            errdefer allocator.destroy(self);
            self.alloc = allocator;

            var newArena = try arena.AllocatorBackedUpbArena.init(allocator);
            errdefer newArena.deinit();

            self.arena = newArena;
            const upbArena: *c.upb_Arena = @ptrCast(newArena.upbArena());
            if (@call(.auto, @field(c, std.fmt.comptimePrint("{s}_new", .{upbNamespace})), .{upbArena})) |msg| {
                self.msg = msg;
                return self;
            }
            return ProtobufErrors.CannotAllocate;
        }

        pub fn deserialize(allocator: *const std.mem.Allocator, buf: []const u8) !*Self {
            var self = try allocator.create(Self);
            errdefer allocator.destroy(self);
            self.alloc = allocator;

            var newArena = try arena.AllocatorBackedUpbArena.init(allocator);
            errdefer newArena.deinit();

            self.arena = newArena;
            const upbArena: *c.upb_Arena = @ptrCast(newArena.upbArena());
            if (@call(.auto, @field(c, std.fmt.comptimePrint("{s}_parse", .{upbNamespace})), .{ buf.ptr, buf.len, upbArena })) |msg| {
                self.msg = msg;
                return self;
            }
            return ProtobufErrors.CannotParse;
        }

        pub fn deinit(self: *Self) void {
            self.arena.deinit();
            self.alloc.destroy(self);
        }

        pub fn serialize(self: *Self, allocator: *const std.mem.Allocator) !*SliceWithUpbArena(u8) {
            var slice = try allocator.create(SliceWithUpbArena(u8));
            errdefer allocator.destroy(slice);
            slice.alloc = allocator;

            var newArena = try arena.AllocatorBackedUpbArena.init(allocator);
            errdefer newArena.deinit();
            slice.arena = newArena;

            var size: usize = 0;
            const upbArena: *c.upb_Arena = @ptrCast(newArena.upbArena());
            if (@call(.auto, @field(c, std.fmt.comptimePrint("{s}_serialize", .{upbNamespace})), .{ self.msg, upbArena, &size })) |msg| {
                slice.slice = msg[0..size];
                return slice;
            }

            return ProtobufErrors.CannotSerialize;
        }
    };
}

test "bindToProto" {
    const DynamicApiRequest = bindToProto("macbox.core.v1.ApiRequest");
    var req = try DynamicApiRequest.init(&std.testing.allocator);
    defer req.deinit();
    var serialized = try req.serialize(&std.testing.allocator);
    defer serialized.deinit();
    var deserialized = try DynamicApiRequest.deserialize(&std.testing.allocator, serialized.slice);
    defer deserialized.deinit();
}

// pub const ApiRequest = struct {
//     const Self = @This();
//     msg: *c.macbox_core_v1_ApiRequest,
//     arena: *arena.AllocatorBackedUpbArena,

//     pub fn init(allocator: *const std.mem.Allocator) !Self {
//         var newArena = try arena.AllocatorBackedUpbArena.init(allocator);
//         errdefer newArena.deinit();
//         if (c.macbox_core_v1_ApiRequest_new(arena)) |msg| {
//             return .{ .msg = msg, .arena = newArena };
//         }
//         return ProtobufErrors.CannotAllocate;
//     }

//     pub fn deserialize(allocator: *const std.mem.Allocator, ser: []const u8) ProtobufErrors!Self {
//         var newArena = try arena.AllocatorBackedUpbArena.init(allocator);
//         errdefer newArena.deinit();
//         if (c.macbox_core_v1_ApiRequest_parse(ser.ptr, ser.len, arena)) |msg| {
//             return .{ .msg = msg, .arena = newArena };
//         }
//         return ProtobufErrors.CannotParse;
//     }

//     pub fn deinit(self: *Self) void {
//         self.arena.deinit();
//     }

//     pub fn serialize(self: *Self) []const u8 {
//         var size: usize = 0;
//         const str = c.macbox_core_v1_ApiRequest_serialize(self.msg, self.arena, &size);

//         return str[0..size];
//     }

//     pub fn set_tid(self: *Self, tid: ?i32) void {
//         if (tid) |_tid| {
//             c.macbox_core_v1_ApiRequest_set_tid(self.msg, _tid);
//         } else {
//             c.macbox_core_v1_ApiRequest_clear_tid(self.msg);
//         }
//     }

//     pub fn get_tid(self: *Self) i32 {
//         return c.macbox_core_v1_ApiRequest_tid(self.msg);
//     }

//     pub fn set_pid(self: *Self, pid: ?i32) void {
//         if (pid) |_pid| {
//             c.macbox_core_v1_ApiRequest_set_pid(self.msg, _pid);
//         } else {
//             c.macbox_core_v1_ApiRequest_clear_pid(self.msg);
//         }
//     }

//     pub fn get_pid(self: *Self) i32 {
//         return c.macbox_core_v1_ApiRequest_pid(self.msg);
//     }

//     pub fn set_payload(self: *Self, payload: ?[]const u8) void {
//         if (payload) |_payload| {
//             c.macbox_core_v1_ApiRequest_set_payload(self.msg, strings.upbStringViewFromString(_payload));
//         } else {
//             c.macbox_core_v1_ApiRequest_clear_payload(
//                 self.msg,
//             );
//         }
//     }

//     pub fn get_payload(self: *Self) ?[]const u8 {
//         return strings.upbStringViewToString(c.macbox_core_v1_ApiRequest_payload(self.msg));
//     }
// };
