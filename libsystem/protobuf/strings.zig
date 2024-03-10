const c = @cImport({
    @cInclude("upb/base/string_view.h");
});

fn upbStringViewToString(u: c.upb_StringView) ?[]const u8 {
    if (u.data) |str| {
        return str[0..u.size];
    }
    return null;
}

fn upbStringViewFromString(s: []const u8) c.upb_StringView {
    return .{
        .size = s.len,
        .data = s.ptr,
    };
}
