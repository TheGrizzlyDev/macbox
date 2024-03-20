const c = @cImport({
    @cInclude("upb/base/string_view.h");
});

pub fn upbStringViewToString(u: c.upb_StringView) ?[]const u8 {
    if (u.data) |str| {
        return str[0..u.size];
    }
    return null;
}

pub fn upbStringViewFromString(s: []const u8) c.upb_StringView {
    return .{
        .size = s.len,
        .data = s.ptr,
    };
}
