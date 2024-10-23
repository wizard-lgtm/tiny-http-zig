const std = @import("std");
const common = @import("./common.zig");
const net = std.net;

const Address = net.Address;

const Request = @import("./request.zig").Request;
const Client = @import("./client.zig").Client;

const Listener = struct { addr: net.Address };

const Pool = std.Thread.Pool;

///
/// Server configs, you may configure the server before initializiton
/// Functions:
/// default -> returns default usage config
///
pub const ServerOptions = struct {
    const Self = @This(); // Self binding
    // Default options
    const DefaultServerOptions = ServerOptions{
        .give_id_to_request = true,
        .logging = false, // !TODO not implemented!
        .on_request_handler = common.default_on_request_handler,
        .addr = "127.0.0.1",
        .port = 4000,
        .jobs_n = 32,
    };
    // gives random uuid to each request
    give_id_to_request: bool,

    // Future planned
    logging: bool,

    on_request_handler: ?common.Handler,
    addr: []const u8,
    port: u16,
    jobs_n: ?usize, // Job size for Thread Pool
    pub fn default() ServerOptions {
        return DefaultServerOptions;
    }
};

// Define default options for listening on a network address
const default_listen_options = net.Address.ListenOptions{
    // Allow the socket to be bound to a port that is in a TIME_WAIT state
    .reuse_address = true,

    // Allow multiple sockets to listen on the same port
    .reuse_port = true,
};

pub const Server = struct {
    allocator: std.mem.Allocator,
    listener: Listener,
    responder: net.Server,
    options: ServerOptions,
    // Pool
    pool: *Pool,

    const Self = @This();
    /// just a basic handler wrapper for threading
    pub fn init(allocator: std.mem.Allocator, options: ?ServerOptions) !*Server {
        var self = try allocator.create(Server);
        if (options) |value| {
            self.options = value;
        } else {
            // Use defaults
            self.options = ServerOptions.default();
        }
        self.allocator = allocator;
        self.listener = Listener{ .addr = try net.Address.parseIp4(self.options.addr, self.options.port) };

        // Init pool
        var pool: Pool = undefined;
        const pool_options: Pool.Options = .{ .allocator = allocator, .n_jobs = null, .track_ids = false };
        try pool.init(pool_options);
        self.pool = &pool;

        return self;
    }
    pub fn deinit(self: *Server) void {
        self.pool.deinit();
        self.responder.deinit();
        self.allocator.destroy(self);
    }
    pub fn listen_http(self: *Server, options: ?Address.ListenOptions) Address.ListenError!void {
        if (options) |value| {
            self.responder = try self.listener.addr.listen(value);
        } else {
            // Use default options
            self.responder = try self.listener.addr.listen(default_listen_options);
        }
    }

    ///
    /// Wrapper for handling functions in server.pool
    /// Since pool does not allow anyerror functions we need to
    /// Handle it by catch
    ///
    fn handler_wrapper(self: *Server, handler: common.Handler, request: *Request) void {
        std.debug.print("Thread opened!\n", .{});
        handler(self, request) catch |err| {
            std.debug.print("Some error happened while executing the handler:\n{any}", .{err});
        };
        // TODO, on error handler
    }

    ///
    /// Just a wrapper function for server.listen and server.mainloop
    ///
    pub fn start(self: *Server) !void {
        try self.listen_http(null);
        try self.mainloop();
    }
    pub fn mainloop(self: *Server) !void {
        std.debug.print("Server started!\n", .{});
        while (true) {
            const request = try self.accept();
            defer request.deinit();
            const on_request = self.options.on_request_handler.?;
            // Spawn on request in server.pool
            try self.pool.*.spawn(handler_wrapper, .{ self, on_request, request });

            std.debug.print("Thread created!", .{});
        }
    }
    pub fn accept(self: *Server) !*Request {
        const connection = try self.responder.accept();
        const client = try Client.init(self.allocator, connection, self.options);
        defer client.deinit();
        const request = try client.next();
        return request;
    }
};
