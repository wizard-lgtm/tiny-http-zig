// Unfinished
const std = @import("std");
const common = @import("./common.zig");

// Std bindings
const net = std.net;
const Allocator = std.mem.Allocator;

// Common type bindings
const Method = common.HTTPMethod;
const HTTPVersion = common.HTTPVersion;
const Header = common.Header;
const StatusCode = common.StatusCode;

const Request = @import("./request.zig").Request;
const Response = @import("./response.zig").Response;

const ReadError = @import("./common.zig").ReadError;

/// A Client is an object that will store a stream to a client
/// and return Request objects.
pub const Client = struct {
    // Allocator
    allocator: Allocator,

    // Address of the client
    remote_addr: net.Address,

    // Is it a safe connection?
    safe: bool,

    stream: net.Stream,

    // set to true if we know that the previous request is the last one
    no_more_requests: bool,

    pub fn init(allocator: Allocator, connection: net.Server.Connection) !*Client {
        var self: *Client = try allocator.create(Client);
        self.allocator = allocator;

        self.remote_addr = connection.address;
        self.stream = connection.stream;

        return self;
    }
    pub fn deinit(self: *Client) void {
        self.allocator.destroy(self);
    }
    pub fn next(self: *Client) !*Request {
        // the client sent a "connection: close" header in this previous request
        //  or is using HTTP 1.0, meaning that no new request will come
        if (self.no_more_requests) {
            return null;
        }

        while (true) {}
    }
    pub fn read(self: *Client) ReadError!Request {
        _ = self;
    }
};
