// Unfinished
const std = @import("std");
const common = @import("./common.zig");
const concat = @import("./utils//string.zig").concat_strings;
// Std bindings
const net = std.net;
const Allocator = std.mem.Allocator;

// Common type bindings
const Method = common.Method;
const HTTPVersion = common.HTTPVersion;
const Header = common.Header;
const StatusCode = common.StatusCode;

pub const Response = struct {
    // Allocator
    allocator: Allocator,
    body: []const u8,
    version: HTTPVersion,
    status_code: StatusCode,
    headers: std.ArrayList(Header),
    data_length: usize,
    chunked_threshold: ?usize,

    pub fn init(allocator: Allocator) !*Response {
        var self = try allocator.create(Response);
        self.allocator = allocator;
        self.headers = std.ArrayListAligned(Header, null).init(self.allocator);
        self.version = HTTPVersion{ .major = 1, .minor = 1 };
        return self;
    }

    pub fn deinit(self: *Response) void {
        self.headers.deinit();
        self.allocator.destroy(self);
    }
    pub fn to_http_string(self: *Response, do_not_send_body: bool) ![]const u8 {
        var buffer = std.ArrayList(u8).init(self.allocator);
        defer buffer.deinit();

        // Add status line
        try buffer.appendSlice(try std.fmt.allocPrint(self.allocator, "HTTP/{d}.{d} {d} {s}\r\n", .{
            self.version.major,
            self.version.minor,
            self.status_code.code,
            self.status_code.message(),
        }));

        // Add headers
        for (self.headers.items) |header| {
            try buffer.appendSlice(try std.fmt.allocPrint(self.allocator, "{s}: {s}\r\n", .{
                header.field,
                header.value,
            }));
        }

        // Add Content-Length header
        try buffer.appendSlice(try std.fmt.allocPrint(self.allocator, "Content-Length: {d}\r\n", .{
            if (do_not_send_body) 0 else self.body.len,
        }));

        // Add body
        if (!do_not_send_body) {
            try buffer.appendSlice("\r\n");
            try buffer.appendSlice(self.body);
        }

        return try buffer.toOwnedSlice();
    }
};
