const std = @import("std");
const Server = @import("./server.zig").Server;
const Request = @import("./request.zig").Request;
const net = std.net;

/// Define a struct to represent the HTTP version
pub const HTTPVersion = struct {
    major: u8, // Major version number (e.g., 1 in HTTP/1.1)
    minor: u8, // Minor version number (e.g., 1 in HTTP/1.1)

    /// Constructor function
    pub fn init(version: []const u8) ReadError!HTTPVersion {
        if (std.mem.eql(u8, version, "HTTP/0.9")) {
            return HTTPVersion{ .major = 0, .minor = 9 };
        } else if (std.mem.eql(u8, version, "HTTP/1.0")) {
            return HTTPVersion{ .major = 1, .minor = 0 };
        } else if (std.mem.eql(u8, version, "HTTP/1.1")) {
            return HTTPVersion{ .major = 1, .minor = 1 };
        } else if (std.mem.eql(u8, version, "HTTP/2.0")) {
            return HTTPVersion{ .major = 2, .minor = 0 };
        } else if (std.mem.eql(u8, version, "HTTP/3.0")) {
            return HTTPVersion{ .major = 3, .minor = 0 };
        } else {
            return ReadError.WrongRequestLine;
        }
    }

    /// Function to print the HTTP version for debugging purposes
    pub fn debugPrint(self: HTTPVersion) void {
        std.debug.print("HTTPVersion({d}, {d})\n", .{ self.major, self.minor });
    }

    /// Function to format the HTTP version as a string
    pub fn fmt(self: HTTPVersion) [13]u8 {
        var buffer: [13]u8 = undefined;
        _ = try std.fmt.bufPrint(&buffer, "HTTP/{d}.{d}", .{ self.major, self.minor }) catch unreachable;
        return buffer;
    }

    /// check equality between two HTTPVersion instances
    pub fn eq(self: HTTPVersion, other: HTTPVersion) bool {
        return self.major == other.major and self.minor == other.minor;
    }
};

/// HTTP request methods
///
/// As per [RFC 7231](https://tools.ietf.org/html/rfc7231#section-4.1) and
/// [RFC 5789](https://tools.ietf.org/html/rfc5789)
pub const HTTPMethod = enum {
    /// `GET`
    Get,

    /// `HEAD`
    Head,

    /// `POST`
    Post,

    /// `PUT`
    Put,

    /// `DELETE`
    Delete,

    /// `CONNECT`
    Connect,

    /// `OPTIONS`
    Options,

    /// `TRACE`
    Trace,

    /// `PATCH`
    Patch,

    /// Request methods not standardized by the IETF
    NonStandard,

    pub fn init(method: []const u8) HTTPMethod {
        if (std.mem.eql(u8, method, "GET")) return HTTPMethod.Get;
        if (std.mem.eql(u8, method, "HEAD")) return HTTPMethod.Head;
        if (std.mem.eql(u8, method, "POST")) return HTTPMethod.Post;
        if (std.mem.eql(u8, method, "PUT")) return HTTPMethod.Put;
        if (std.mem.eql(u8, method, "DELETE")) return HTTPMethod.Delete;
        if (std.mem.eql(u8, method, "CONNECT")) return HTTPMethod.Connect;
        if (std.mem.eql(u8, method, "OPTIONS")) return HTTPMethod.Options;
        if (std.mem.eql(u8, method, "TRACE")) return HTTPMethod.Trace;
        if (std.mem.eql(u8, method, "PATCH")) return HTTPMethod.Patch;
        return HTTPMethod.NonStandard;
    }
};

/// Status code of a request or response.
pub const StatusCode = struct {
    code: u16,

    pub fn init(code: u16) StatusCode {
        return StatusCode{ .code = code };
    }

    pub fn message(self: StatusCode) []const u8 {
        return switch (self.code) {
            100 => "Continue",
            101 => "Switching Protocols",
            102 => "Processing",
            103 => "Early Hints",

            200 => "OK",
            201 => "Created",
            202 => "Accepted",
            203 => "Non-Authoritative Information",
            204 => "No Content",
            205 => "Reset Content",
            206 => "Partial Content",
            207 => "Multi-Status",
            208 => "Already Reported",
            226 => "IM Used",

            300 => "Multiple Choices",
            301 => "Moved Permanently",
            302 => "Found",
            303 => "See Other",
            304 => "Not Modified",
            305 => "Use Proxy",
            307 => "Temporary Redirect",
            308 => "Permanent Redirect",

            400 => "Bad Request",
            401 => "Unauthorized",
            402 => "Payment Required",
            403 => "Forbidden",
            404 => "Not Found",
            405 => "Method Not Allowed",
            406 => "Not Acceptable",
            407 => "Proxy Authentication Required",
            408 => "Request Timeout",
            409 => "Conflict",
            410 => "Gone",
            411 => "Length Required",
            412 => "Precondition Failed",
            413 => "Payload Too Large",
            414 => "URI Too Long",
            415 => "Unsupported Media Type",
            416 => "Range Not Satisfiable",
            417 => "Expectation Failed",
            421 => "Misdirected Request",
            422 => "Unprocessable Entity",
            423 => "Locked",
            424 => "Failed Dependency",
            426 => "Upgrade Required",
            428 => "Precondition Required",
            429 => "Too Many Requests",
            431 => "Request Header Fields Too Large",
            451 => "Unavailable For Legal Reasons",

            500 => "Internal Server Error",
            501 => "Not Implemented",
            502 => "Bad Gateway",
            503 => "Service Unavailable",
            504 => "Gateway Timeout",
            505 => "HTTP Version Not Supported",
            506 => "Variant Also Negotiates",
            507 => "Insufficient Storage",
            508 => "Loop Detected",
            510 => "Not Extended",
            511 => "Network Authentication Required",
            else => "Unknown",
        };
    }
};

/// Field of a header (eg. `Content-Type`, `Content-Length`, etc.)
///
/// Comparison between two `HeaderField`s ignores case.s
pub const Header = struct {
    field: []const u8,
    value: []const u8,

    pub fn debug(self: Header) void {
        std.debug.print("Header(field: {s}, value: {s})\n", .{ self.field, self.value });
    }

    /// Compares two Header structs for equality.
    pub fn eq(self: Header, other: Header) bool {
        return std.mem.eql(u8, self.field, other.field) and std.mem.eql(u8, self.value, other.value);
    }

    /// Parses a single header string into a Header struct.
    ///
    /// This function can handle headers that may have leading/trailing whitespace,
    /// as well as headers that use \r\n line endings.
    ///
    pub fn parse(header_str: []const u8) ReadError!Header {
        // Trim leading and trailing whitespace, including newlines
        const trimmed = std.mem.trim(u8, header_str, " \n\r");

        // Find the first colon
        const colon_index = std.mem.indexOfScalar(u8, trimmed, ':') orelse return error.WrongHeader;

        // Split the string at the colon
        const field = std.mem.trim(u8, trimmed[0..colon_index], " ");
        const value = std.mem.trim(u8, trimmed[colon_index + 1 ..], " \r\n");

        return Header{ .field = field, .value = value };
    }
};

/// Error that can happen when reading a request.
pub const ReadError = error{
    WrongRequestLine,
    WrongHeader,
    ExpectationFailed,
    ReadIoError,
};

///
/// Handler type for declaring handler functions
/// !TODO Future planned: implement ServerContext
///
pub const Handler: type = fn (*Server, *Request) anyerror!void;
