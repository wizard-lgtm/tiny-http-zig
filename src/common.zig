const std = @import("std");

/// Define a struct to represent the HTTP version
const HTTPVersion = struct {
    major: u8, // Major version number (e.g., 1 in HTTP/1.1)
    minor: u8, // Minor version number (e.g., 1 in HTTP/1.1)

    /// Constructor function
    pub fn init(major: u8, minor: u8) HTTPVersion {
        return HTTPVersion{ .major = major, .minor = minor };
    }

    /// Function to print the HTTP version for debugging purposes
    pub fn debugPrint(self: HTTPVersion) void {
        std.debug.print("HTTPVersion({d}, {d})\n", .{ self.major, self.minor });
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
pub const Method = enum {
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
};

/// Status code of a request or response.
pub const StatusCode = struct {
    code: u16,

    pub fn init(code: u16) StatusCode {
        return StatusCode{ .code = code };
    }

    pub fn defaultReasonPhrase(self: StatusCode) []const u8 {
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

    /// Parses a header string into a Header struct.
    ///
    /// - `InvalidHeader`: Returned if the header string is not in the correct format.s
    pub fn parse(header_str: []const u8) !Header {
        var parts = std.mem.split(u8, header_str, ":");

        const occurs = std.mem.count(u8, header_str, ":");

        std.debug.print("{}\n", .{occurs});

        if (occurs != 1) return error.InvalidHeader;

        const field: []const u8 = parts.next() orelse return error.InvalidHeader;
        const value: []const u8 = parts.next() orelse return error.InvalidHeader;

        return Header{ .field = std.mem.trim(u8, field, " "), .value = std.mem.trim(u8, value, " ") };
    }
};
