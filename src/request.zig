const std = @import("std");
const common = @import("./common.zig");
const Response = @import("./response.zig").Response;

// Std bindings
const io = std.io;
const net = std.net;
const fmt = std.fmt;

// Common type bindings
const Method = common.Method;
const HTTPVersion = common.HTTPVersion;
const Header = common.Header;
const StatusCode = common.StatusCode;

pub const Request = struct {
    // where to read the body from
    data_reader: net.Stream.Reader,

    // if this writer is empty, then the request has been answered
    response_writer: ?net.Stream.Writer,

    remote_addr: net.Address,

    // true if HTTPS, false if HTTP
    secure: bool,

    method: Method,

    path: []const u8,

    http_version: HTTPVersion,

    headers: []Header,

    body_length: ?usize,

    // true if a `100 Continue` response must be sent when `as_reader()` is called
    must_send_continue: bool,

    // TODO
    // notify_when_responded: ?std.sync.Channel(*std.heap.GeneralPurposeAllocator, void).Sender,

    pub fn secure(self: *Request) bool {
        return self.secure;
    }

    pub fn method(self: *Request) Method {
        return self.method;
    }

    pub fn url(self: *Request) []const u8 {
        return self.path;
    }

    pub fn headers(self: *Request) []Header {
        return self.headers;
    }

    pub fn http_version(self: *Request) HTTPVersion {
        return self.http_version;
    }

    pub fn body_length(self: *Request) ?usize {
        return self.body_length;
    }

    pub fn remote_addr(self: *Request) ?net.Address {
        return self.remote_addr;
    }
};
