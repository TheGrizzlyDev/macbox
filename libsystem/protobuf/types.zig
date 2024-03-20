const proto = @cImport({
    @cInclude("proto/protocol/v1/rpc.upb.h");
    @cInclude("proto/macbox/core/v1/macbox.upb.h");
});

const bindindgs = @import("bindings.zig");

pub const Request = bindindgs.bindToProto(proto, "protocol.v1.Request");
pub const Response = bindindgs.bindToProto(proto, "protocol.v1.Response");

pub const ApiRequest = bindindgs.bindToProto(proto, "macbox.core.v1.ApiRequest");
pub const ApiResponse = bindindgs.bindToProto(proto, "macbox.core.v1.ApiResponse");
pub const CwdResponse = bindindgs.bindToProto(proto, "macbox.core.v1.CwdResponse");
