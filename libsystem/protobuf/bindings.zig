const std = @import("std");
const arena = @import("arena.zig");
const strings = @import("strings.zig");

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

pub fn bindToProto(comptime c: type, comptime fully_qualified_name: []const u8) type {
    const upbNamespace: []const u8 = blk: {
        var ns: []const u8 = &[_]u8{};
        for (fully_qualified_name) |char| {
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

        pub fn get(self: *Self, comptime field: []const u8) blk: {
            break :blk switch (@typeInfo(@TypeOf(@field(c, std.fmt.comptimePrint("{s}_{s}", .{ upbNamespace, field }))))) {
                .Fn => |fnTypeInfo| fnTypeInfo.return_type orelse anyopaque,
                else => @compileError(std.fmt.comptimePrint("'{s}' is not a field of this proto type", .{field})),
            };
        } {
            return @call(.auto, @field(c, std.fmt.comptimePrint("{s}_{s}", .{ upbNamespace, field })), .{self.msg});
        }

        pub fn getString(self: *Self, comptime field: []const u8) ?[]const u8 {
            const u = self.get(field);
            if (u.data) |str| {
                return str[0..u.size];
            }
            return null;
        }

        pub fn set(self: *Self, comptime field: []const u8, value: anytype) void {
            return @call(.auto, @field(c, std.fmt.comptimePrint("{s}_set_{s}", .{ upbNamespace, field })), .{ self.msg, value });
        }

        pub fn setString(self: *Self, comptime field: []const u8, value: []const u8) void {
            const s = c.upb_StringView{
                .size = value.len,
                .data = value.ptr,
            };
            return self.set(field, s);
        }

        pub fn clear(self: *Self, comptime field: []const u8) void {
            return @call(.auto, @field(c, std.fmt.comptimePrint("{s}_clear_{s}", .{ upbNamespace, field })), .{self.msg});
        }
    };
}

test "bindToProto" {
    const c = @cImport({
        @cInclude("proto/macbox/core/v1/macbox.upb.h");
    });
    const DynamicApiRequest = bindToProto(c, "macbox.core.v1.ApiRequest");
    var req = try DynamicApiRequest.init(&std.testing.allocator);
    defer req.deinit();
    req.set("pid", 123);
    var serialized = try req.serialize(&std.testing.allocator);
    defer serialized.deinit();
    var deserialized = try DynamicApiRequest.deserialize(&std.testing.allocator, serialized.slice);
    defer deserialized.deinit();
    const pid = deserialized.get("pid");
    try std.testing.expect(123 == pid);
    deserialized.clear("pid");
    const clearedPid = deserialized.get("pid");
    try std.testing.expect(0 == clearedPid);
}
