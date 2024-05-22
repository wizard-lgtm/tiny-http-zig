// Unfinished
const std = @import("std");
const common = @import("./common.zig");

// Std bindings
const net = std.net;
const Allocator = std.mem.Allocator;

// Common type bindings
const Method = common.Method;
const HTTPVersion = common.HTTPVersion;
const Header = common.Header;
const StatusCode = common.StatusCode;

pub const Response = struct {
    reader: net.Stream.Reader,
    status_code: StatusCode,
    headers: std.ArrayList(Header),
    data_length: ?usize,
    chunked_threshold: ?usize,

    pub fn init(allocator: *Allocator, reader: net.Stream.Reader, status_code: StatusCode) !Response {
        return Response{
            .reader = reader,
            .status_code = status_code,
            .headers = try std.ArrayListUnmanaged(Header).init(allocator),
            .data_length = null,
            .chunked_threshold = null,
        };
    }

    pub fn deinit(self: *Response) void {
        self.headers.deinit();
    }
};
