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
const generate_uuid = @import("./utils/uuid.zig").generate_uuid;
const ServerOptions = @import("./server.zig").ServerOptions;

/// A Client is an object that will store a stream to a client
/// and return Request objects.
pub const Client = struct {
    // Allocator
    allocator: Allocator,

    // Address of the client
    remote_addr: net.Ip4Address,

    // Is it a safe connection?
    safe: bool,

    stream: net.Stream,

    options: ServerOptions,

    // set to true if we know that the previous request is the last one
    no_more_requests: bool,

    pub fn init(allocator: Allocator, connection: net.Server.Connection, options: ServerOptions) !*Client {
        var self: *Client = try allocator.create(Client);
        self.allocator = allocator;

        self.remote_addr = connection.address.in;
        self.stream = connection.stream;
        self.options = options;

        return self;
    }
    pub fn deinit(self: *Client) void {
        self.allocator.destroy(self);
    }
    pub fn next(self: *Client) !*Request {
        // the client sent a "connection: close" header in this previous request
        //  or is using HTTP 1.0, meaning that no new request will come
        // TODO
        // if (self.no_more_requests) {
        //     return null;
        // }

        const buffer = try self.read_stream();
        var request = try Request.init(buffer, self.allocator, false, self.remote_addr, self.safe, self.stream);

        if (self.options.give_id_to_request) {
            request.ray_id = generate_uuid();
        }
        return request;
    }
    ///
    /// Reading request buffer
    /// Returns a string
    ///
    pub fn read_stream(self: *Client) ![]u8 {
        const chunk_size: usize = 256;
        var chunk_count: u16 = 1; // How many chunks are allocated
        var total_read: usize = 0;
        var bytes_read: usize = 0;

        // allocate buffer for read
        var buffer = try self.allocator.alloc(u8, chunk_size);

        //Read with chunks
        while (true) {
            bytes_read = try self.stream.read(buffer[total_read..]);
            if (bytes_read == 0) {
                break; // End of the stream
            }

            total_read += bytes_read;

            // Debug

            // std.debug.print("bytes read: {}\n", .{bytes_read});
            // std.debug.print("total len of buffer: {}\n", .{buffer.len});

            // Check if we need more size
            if (total_read >= buffer.len) {
                // Extend buffer size
                chunk_count += 1;
                buffer = try self.allocator.realloc(buffer, chunk_size * chunk_count);
            } else {
                break; // All data read
            }
        }

        return buffer;
    }
};
