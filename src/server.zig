const std = @import("std");
const common = @import("./common.zig");
const net = std.net;

const Address = net.Address;

const Request = @import("./request.zig").Request;
const Client = @import("./client.zig").Client;

const Listener = struct { addr: net.Address };

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
        .on_request_handler = null,
        .addr = "127.0.0.1",
        .port = 4000,
    };
    // gives random uuid to each request
    give_id_to_request: bool,

    // Future planned
    logging: bool,

    on_request_handler: ?*const common.Handler,
    addr: []const u8,
    port: u16,
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

/// just a basic handler wrapper for threading
fn handler_wrapper(h: common.Handler) void() {
    // Execute the handler and handle error with catch
    h() catch |err| {
        std.debug.print("some error happened while executing handler! {any}\n", .{err});
    };
}

pub const Server = struct {
    allocator: std.mem.Allocator,
    listener: Listener,
    responder: net.Server,
    options: ServerOptions,

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
        return self;
    }
    pub fn deinit(self: *Server) void {
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
    pub fn accept(self: *Server) !*Request {
        const connection = try self.responder.accept();
        const client = try Client.init(self.allocator, connection, self.options);
        defer client.deinit();
        const request = try client.next();
        return request;
    }
};
