const std = @import("std");
const net = std.net;

const Address = net.Address;

const Request = @import("./request.zig").Request;
const Client = @import("./client.zig").Client;

const Listener = struct { addr: net.Address };

pub const ServerOptions = struct {
    // gives random uuid to each request
    give_id_to_request: bool,

    // Future planned
    logging: bool,
};

pub const DefaultServerOptions = ServerOptions{ .give_id_to_request = true, .logging = false };

const default_listen_options = net.Address.ListenOptions{
    .reuse_address = true,
    .reuse_port = true,
};

pub const Server = struct {
    allocator: std.mem.Allocator,
    listener: Listener,
    responder: net.Server,
    options: ServerOptions,

    pub fn init(allocator: std.mem.Allocator, addr: []const u8, port: u16, options: ?ServerOptions) !*Server {
        var self = try allocator.create(Server);
        self.allocator = allocator;
        self.listener = Listener{ .addr = try net.Address.parseIp4(addr, port) };
        if (options) |value| {
            self.options = value;
        } else {
            // Use defaults
            self.options = DefaultServerOptions;
        }
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
