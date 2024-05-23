const std = @import("std");
const common = @import("./common.zig");
const Response = @import("./response.zig").Response;

// Std bindings
const io = std.io;
const net = std.net;
const fmt = std.fmt;
const Allocator = std.mem.Allocator;

// Common type bindings
const Method = common.Method;
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
    pub fn init(buffer: []const u8, allocator: std.mem.Allocator, must_send_continue: bool, remote_addr: net.Address, secure: bool) ReadError!Request {

        // Split the request
        var parts = std.mem.splitAny(u8, buffer, "\r\n\r\n");
        const head = parts.first();

        // Split head into status line and headers
        var head_parts = std.mem.splitAny(u8, head, "\r\n");

        // Parse status line
        const status_line = head_parts.first();
        var status_line_parts = std.mem.splitScalar(u8, status_line, ' ');

        const method = Method.init(status_line_parts.first());
        const path = status_line_parts.next() orelse ReadError.WrongRequestLine;
        const http_version = HTTPVersion.init(status_line_parts.first()) catch return ReadError.WrongRequestLine;

        // Parse raw headers to hashmap
        var headers_lines: std.mem.SplitIterator(u8, std.mem.DelimiterType.scalar) = undefined;

        while (head_parts.next()) |headers_raw| {
            headers_lines = std.mem.splitScalar(u8, headers_raw, '\n');
        }

        // Parse headers
        var headers = std.ArrayList(
            Header,
        ).init(allocator);

        while (true) {
            const line = headers_lines.next() orelse ReadError.WrongHeader;
            if (line == null) {
                break; // Exit if end of lines
            }
            const header = try Header.parse(line);

            _ = try headers.append(header);
        }

        // Parse body
        const body = parts.next() orelse "";

        var self = try allocator.create(Request);

        self.allocator = allocator;
        self.body_length = body.len;
        self.headers = headers;
        self.http_version = http_version;
        self.method = method;
        self.path = path;

        self.must_send_continue = must_send_continue;
        self.remote_addr = remote_addr;
        self.secure = secure;

        return self;
    }

    pub fn respond(self: *Request, buffer: []const u8) std.net.Stream.WriteError!void {
        _ = try self.response_writer.?.writeAll(buffer);
    }
};
