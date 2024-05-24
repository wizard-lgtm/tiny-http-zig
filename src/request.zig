const std = @import("std");
const common = @import("./common.zig");
const Response = @import("./response.zig").Response;

// Std bindings
const io = std.io;
const net = std.net;
const fmt = std.fmt;
const Allocator = std.mem.Allocator;

// Common type bindings
const Method = common.HTTPMethod;
const HTTPMethod = common.HTTPMethod;

const HTTPVersion = common.HTTPVersion;
const Header = common.Header;
const StatusCode = common.StatusCode;

const ReadError = @import("./common.zig").ReadError;

pub const Request = struct {
    // Allocator
    allocator: Allocator,

    // where to read the body from
    // data_reader: net.Stream.Reader,

    // if this writer is empty, then the request has been answered
    response_writer: ?net.Stream.Writer,

    remote_addr: net.Address,

    // true if HTTPS, false if HTTP
    secure: bool,

    method: Method,

    path: []const u8,

    http_version: HTTPVersion,

    headers: std.ArrayList(Header),

    body_length: ?usize,

    // true if a `100 Continue` response must be sent when `as_reader()` is called
    must_send_continue: bool,

    // TODO
    // notify_when_responded: ?std.sync.Channel(*std.heap.GeneralPurposeAllocator, void).Sender,

    ///
    /// Parses raw string request buffer
    /// Returns a HttpObject
    ///
    pub fn init(buffer: []const u8, allocator: std.mem.Allocator, must_send_continue: bool, remote_addr: net.Address, secure: bool) !*Request {
        var self = try allocator.create(Request);

        self.allocator = allocator;

        // Parses request buffer and sets most of the parts of the request
        _ = try self.parse_request_buffer(buffer);

        self.must_send_continue = must_send_continue;
        self.secure = secure;
        self.remote_addr = remote_addr;
        self.response_writer = null;

        return self;
    }

    test "request init" {
        const allocator = std.testing.allocator;
        const fake_addr = std.net.Address.initIp4(.{ 127, 0, 0, 1 }, 49505);

        const buffer =
            "POST /submit HTTP/1.1\r\n" ++
            "Host: 127.0.0.1:49505\r\n" ++
            "User-Agent: zig-testing\r\n" ++
            "Accept: */*\r\n" ++
            "Content-Type: application/x-www-form-urlencoded\r\n" ++
            "Content-Length: 13\r\n" ++
            "Connection: close\r\n" ++
            "\r\n" ++
            "Body!";
        // Test request buffer
        const secure = false;
        const must_send_continue = false;

        const request = try Request.init(buffer, allocator, must_send_continue, fake_addr, secure);
        defer _ = request.deinit();

        // Print it
        request.fmt();
    }

    pub fn deinit(self: *Request) void {
        self.headers.deinit();
        self.allocator.destroy(self);
    }

    const StatusLineParts = struct { method: HTTPMethod, path: []const u8, http_version: HTTPVersion };
    fn parse_status_line(status_line: []const u8) ReadError!StatusLineParts {
        // Ensure the status line is present
        var status_line_parts = std.mem.splitScalar(u8, status_line, ' ');

        // Ensure there are enough parts in the status line
        const method_part = status_line_parts.first();
        const path_part = status_line_parts.next() orelse return ReadError.WrongRequestLine;
        const version_part = status_line_parts.next() orelse return ReadError.WrongRequestLine;

        const method = HTTPMethod.init(method_part);
        const path = path_part;
        const http_version = try HTTPVersion.init(version_part);

        return StatusLineParts{ .method = method, .path = path, .http_version = http_version };
    }

    test "parse status line" {
        // const valid_status_line = "GET /index.html HTTP/1.1";
        // const valid_result = try parse_status_line(valid_status_line);

        // std.debug.print("valid status line {any} {s} {any}\n", .{ valid_result.method, valid_result.path, valid_result.http_version });

        // const invalid_status_line = "GET HTTP/1.9";
        // const invalid_result = parse_status_line(invalid_status_line);

        // try std.testing.expectEqual(valid_result, StatusLineParts{ .http_version = HTTPVersion{ .major = 1, .minor = 1 }, .path = "/index.html", .method = HTTPMethod.Get });
        // try std.testing.expectEqual(invalid_result, ReadError.WrongRequestLine);
        // const valid_status_line = "GET /index.html HTTP/1.1";
        // const valid_result = try parse_status_line(valid_status_line);

        // std.debug.print("valid status line {any} {s} {any}\n", .{ valid_result.method, valid_result.path, valid_result.http_version });

        // const invalid_status_line = "GET HTTP/1.9";
        // const invalid_result = parse_status_line(invalid_status_line);

        // try std.testing.expectEqual(valid_result, StatusLineParts{ .http_version = HTTPVersion{ .major = 1, .minor = 1 }, .path = "/index.html", .method = HTTPMethod.Get });
        // try std.testing.expectEqual(invalid_result, ReadError.WrongRequestLine);
    }

    fn parse_headers(allocator: std.mem.Allocator, headers_str: []const u8) !std.ArrayList(Header) {
        // Initialize a hashmap to store headers
        var headers_map = std.ArrayList(Header).init(allocator);

        // Split the headers string by lines
        var headers_lines = std.mem.splitSequence(u8, headers_str, "\r\n");

        while (true) {
            const line = headers_lines.next() orelse break;
            if (std.mem.trim(u8, line, " \t").len == 0) continue; // Skip empty lines

            const header = try Header.parse(line);
            try headers_map.append(header);
        }

        return headers_map;
    }

    test "parse header" {
        const allocator = std.testing.allocator;

        const headers_str =
            \\Content-Type: text/html
            \\Content-Length: 123
            \\Connection: keep-alive
        ;

        const invalid_headers_str =
            \\Content-Type  text/html
            \\   Conten  :t-Length: 123
            \\Connection
        ;

        // Test valid headers
        const headers = try parse_headers(allocator, headers_str);
        defer headers.deinit();

        std.debug.print("Valid Headers:\n", .{});
        for (headers.items) |header| {
            header.debug();
        }
        _ = try std.testing.expect(headers.items.len > 0);

        // Test invalid headers
        const invalid_headers_result = parse_headers(allocator, invalid_headers_str);
        try std.testing.expectEqual(error.WrongHeader, invalid_headers_result);
    }

    fn parse_request_buffer(self: *Request, buffer: []const u8) !void {
        // Split request to two parts
        // Head and body

        var parts = std.mem.splitSequence(u8, buffer, "\r\n\r\n");
        const head = parts.first();
        const body = parts.next() orelse "";

        // Split head into status line and headers
        var head_parts = std.mem.split(u8, head, "\r\n");

        const status_line = head_parts.next() orelse return ReadError.WrongHeader;

        const status_line_parts = try parse_status_line(status_line);

        var headers = std.ArrayList(Header).init(self.allocator);
        while (head_parts.next()) |line| {
            const header = try Header.parse(line);
            _ = try headers.append(header);
        }

        // Assemble all the parts together
        self.body_length = body.len;
        self.headers = headers;
        self.http_version = status_line_parts.http_version;
        self.method = status_line_parts.method;
        self.path = status_line_parts.path;
    }

    pub fn fmt(self: *Request) void {
        std.debug.print("Request:\n", .{});
        std.debug.print("  Secure: {}\n", .{self.secure});
        std.debug.print("  Method: {any}\n", .{self.method});
        std.debug.print("  Path: {s}\n", .{self.path});
        std.debug.print("  HTTP Version: {any}\n", .{self.http_version});
        std.debug.print("  Remote Address: {any}\n", .{self.remote_addr});
        std.debug.print("  Must Send Continue: {any}\n", .{self.must_send_continue});
        std.debug.print("  Body Length: {?}\n", .{self.body_length});
        std.debug.print("  Headers:\n", .{});
        for (self.headers.items) |header| {
            std.debug.print("   {s}: {s}\n", .{ header.field, header.value });
        }
    }

    pub fn respond(self: *Request, buffer: []const u8) std.net.Stream.WriteError!void {
        _ = try self.response_writer.?.writeAll(buffer);
    }
};
