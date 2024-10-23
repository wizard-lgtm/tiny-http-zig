const std = @import("std");

const Server = @import("./server.zig").Server;
const ServerConfig = @import("./server.zig").ServerOptions;
const Request = @import("./request.zig").Request;
const Response = @import("./response.zig").Response;

const common = @import("./common.zig");

fn on_request(server: *Server, request: *Request) !void {
    std.debug.print("on request handler hit\n", .{});
    const allocator = server.allocator;

    std.debug.print("New request came up!\n", .{});

    const response = try Response.init(allocator);
    defer _ = response.deinit();

    response.body = "Kirwe";
    response.status_code = common.StatusCode.init(200);

    _ = try response.headers.append(try common.Header.parse("Content-Type: text/plain"));
    _ = try request.respond(response);

    std.debug.print("Response Sent!\n", .{});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const config = ServerConfig{
        .port = 4002,
        .give_id_to_request = false,
        .logging = false, // Not implemented
        .addr = "127.0.0.1",
        .on_request_handler = on_request,
        .jobs_n = null,
    };
    const server = try Server.init(allocator, config);
    defer _ = server.deinit();
    try server.start();
}
