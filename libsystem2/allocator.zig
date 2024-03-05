const std = @import("std");

var allocator: ?std.mem.Allocator = null;
var l = std.Thread.RwLock{};

pub fn get() std.mem.Allocator {
    l.lockShared();
    if (allocator) |a| {
        defer l.unlockShared();
        return a;
    }

    l.unlockShared();
    l.lock();
    defer l.unlock();

    if (allocator == null) {
        allocator = std.heap.page_allocator;
    }

    return allocator.?;
}
