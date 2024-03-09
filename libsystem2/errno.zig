const c = @cImport({
    @cInclude("libsystem2/errno.h");
});

const Error = enum {
    AccessPermissionDenied,
};

pub fn set_errno(err: Error) void {
    c.macbox_set_errno(switch (err) {
        .AccessPermissionDenied => c.EACCES,
    });
}
