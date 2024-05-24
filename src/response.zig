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

    pub fn init(allocator: *Allocator) !Response {
        var self = try allocator.create(Response);
        self.allocator = allocator;
        self.headers = try std.ArrayList(Header).init(self.allocator);
        self.version = HTTPVersion{ .major = 1, .minor = 1 };
        return self;
    }

    pub fn deinit(self: *Response) void {
        self.headers.deinit();
        self.allocator.destroy(self);
    }

    pub fn to_http_string(self: *Response, do_not_send_body: bool) ![]const u8 {
        const buffer = try self.allocator.alloc(u8, 0);
        const status_str = try self.allocator.alloc(u8, 0);
        const version_str = try self.allocator.alloc(u8, 0);
        const length_str = try self.allocator.alloc(u8, 0);
        defer self.allocator.free(status_str);
        defer self.allocator.free(version_str);
        defer self.allocator.free(length_str);

        // Add status line
        _ = try std.fmt.bufPrint(version_str, "HTTP/{d}.{d}", .{ self.version.major, self.version.minor });
        _ = try concat(self.allocator, &buffer, version_str);

        _ = try std.fmt.bufPrint(status_str, "{d}", .{self.status_code.code});
        _ = try concat(self.allocator, &buffer, status_str);

        _ = try concat(self.allocator, &buffer, " ");

        _ = try concat(self.allocator, &buffer, self.status_code.message());
        _ = try concat(self.allocator, &buffer, "\r\n");

        // Add headers
        for (self.headers.items) |header| {
            _ = try concat(self.allocator, &buffer, header.field);
            _ = try concat(self.allocator, &buffer, ": ");
            _ = try concat(self.allocator, &buffer, header.value);
            _ = try concat(self.allocator, &buffer, "\r\n");
        }

        // Finally, Add size to header
        _ = try std.fmt.bufPrint(version_str, "Content-Length: {d}", .{buffer.len});
        _ = try concat(self.allocator, &buffer, length_str);

        // Add body
        if (!do_not_send_body) {
            _ = try concat(self.allocator, &buffer, "\r\n");
            _ = try concat(self.allocator, &buffer, self.body);
        }

        return buffer;
    }
};
