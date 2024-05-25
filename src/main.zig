const std = @import("std");

const Server = @import("./server.zig").Server;
const Request = @import("./request.zig").Request;
const Response = @import("./response.zig").Response;

const common = @import("./common.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const server = try Server.init(allocator, "127.0.0.1", 4000, null);
    defer _ = server.deinit();

    _ = try server.listen_http(null);
    while (true) {
        const request = try server.accept();
        defer _ = request.deinit();

        std.debug.print("New request came up!\n", .{});

        const response = try Response.init(allocator);
        defer _ = response.deinit();

        response.body = "Kirwe";
        response.status_code = common.StatusCode.init(200);

        _ = try response.headers.append(try common.Header.parse("Content-Type: text/plain"));
        _ = try request.respond(response);

        std.debug.print("Response Sent!\n", .{});
    }
}
