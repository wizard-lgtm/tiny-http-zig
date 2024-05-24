const std = @import("std");
const common = @import("./common.zig");
const Header = common.Header;
const ReadError = common.ReadError;
const HTTPMethod = common.HTTPMethod;
const HTTPVersion = common.HTTPVersion;

const Request = @import("./request.zig").Request;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const fake_addr = std.net.Address.initIp4(.{ 127, 0, 0, 1 }, 49505);

    const buffer =
        "POST /submit HTTP/1.1\r\n" ++
        "Host: 127.0.0.1:49505\r\n" ++
        "User-Agent: zig-testing\r\n" ++
        "Accept: */*\r\n" ++
        "Content-Type: application/x-www-form-urlencoded\r\n" ++
        "Content-Length: 13\r\n" ++
        "Connection: close\r\n" ++
        "\r\n" ++
        "Body!";
    // Test request buffer
    const secure = false;
    const must_send_continue = false;
    const request = try Request.init(buffer, allocator, must_send_continue, fake_addr, secure);
    defer _ = request.deinit();

    // Print it
    request.fmt();
}
