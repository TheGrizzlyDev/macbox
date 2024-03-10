const std = @import("std");

const c = @cImport({
    @cInclude("upb/mem/arena.h");
});

pub const ArenaCreationError = error{
    failed_to_create,
};

pub const AllocatorBackedUpbArena = extern struct {
    const Self = @This();
    func: *const anyopaque,
    allocator: *const std.mem.Allocator,
    arena: *c.upb_Arena,

    pub fn init(alloc: *const std.mem.Allocator) !*Self {
        var self = try alloc.create(AllocatorBackedUpbArena);
        errdefer alloc.destroy(self);
        self.allocator = alloc;
        self.func = &AllocatorBackedUpbArena.upbAllocFunc;

        if (c.upb_Arena_Init(null, 0, @ptrCast(self))) |arena| {
            self.arena = arena;
        } else {
            return ArenaCreationError.failed_to_create;
        }

        return self;
    }

    pub fn deinit(self: *Self) void {
        c.upb_Arena_Free(self.arena);
        self.allocator.destroy(self);
    }

    export fn upbAllocFunc(self: *Self, ptr: [*c]u8, old_size: usize, size: usize) [*c]u8 {
        _ = old_size;
        if (ptr == null) {
            const block = self.allocator.alloc(u8, size + @sizeOf(usize)) catch return null;
            std.mem.writeInt(usize, block[0..@sizeOf(usize)], size, .Big);
            return block[@sizeOf(usize)..].ptr;
        }

        const fullBlock: [*]u8 = @ptrFromInt(@intFromPtr(ptr) - @sizeOf(usize));
        const requestedBlockSize = std.mem.readInt(usize, fullBlock[0..@sizeOf(usize)], .Big);
        const block = fullBlock[0..(requestedBlockSize + @sizeOf(usize))];

        if (size == 0) {
            self.allocator.free(block);
            return null;
        }
        const mem = self.allocator.realloc(block, size) catch return null;
        return mem.ptr;
    }

    pub fn upbArena(self: *Self) *c.upb_Arena {
        return self.arena;
    }
};

test "upb uses a zig allocator and does not leak" {
    var arena = try AllocatorBackedUpbArena.init(&std.testing.allocator);
    defer arena.deinit();
    try std.testing.expect(c.upb_Arena_Malloc(arena.upbArena(), 1) != null);
}
