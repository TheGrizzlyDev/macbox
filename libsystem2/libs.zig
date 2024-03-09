const std = @import("std");
const system = std.os.system;

const c = @cImport({
    @cInclude("unistd.h");
    @cInclude("sys/socket.h");
});

const RTLD_NEXT = @as(*anyopaque, @ptrFromInt(@as(usize, @bitCast(@as(isize, @as(c_int, -1))))));

pub const DlError = error{SymbolNotFound};

fn find_signature_type(comptime name: [*:0]const u8) type {
    return @TypeOf(@field(c, std.mem.span(name)));
}

pub fn dlsym(comptime name: [*:0]const u8) !*find_signature_type(name) {
    // TODO: add a cache
    if (@call(.never_tail, system.dlsym, .{ RTLD_NEXT, name })) |func| {
        return @as(*find_signature_type(name), @ptrCast(@alignCast(func)));
    } else {
        return DlError.SymbolNotFound;
    }
}
