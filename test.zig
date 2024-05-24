const std = @import("std");
const common = @import("./src/common.zig");
const Header = common.Header;

const Request = @import("./src/request.zig").Request;

test "test strict headers" {

    // These should not throw an error (valid headers)
    std.debug.print("{any}\n", .{Header.parse("Transfer-Encoding: chunked") != error.InvalidHeader});
    try std.testing.expect(Header.parse("Transfer-Encoding: chunked") != error.InvalidHeader);
    try std.testing.expect(Header.parse("Transfer-Encoding: chunked ") != error.InvalidHeader);
    try std.testing.expect(Header.parse("Transfer-Encoding:   chunked ") != error.InvalidHeader);

    // TODO
    // These should throw an InvalidHeader error (invalid headers)
    // try std.testing.expect(Header.parse("Transfer-Encoding : chunked") == e); // space before colon
    // try std.testing.expect(Header.parse(" Transfer-Encoding: chunked") == e); // leading space
    // try std.testing.expect(Header.parse("Transfer Encoding: chunked") == e); // missing hyphen
    // try std.testing.expect(Header.parse(" Transfer\tEncoding : chunked") == e); // spaces and tab characters
}

test "init request" {
    const allocator = std.testing.allocator;
    const raw_request =
        "GET / HTTP/1.1\r\n" ++
        "Host: example.com\r\n" ++
        "User-Agent: curl/7.64.1\r\n" ++
        "Accept: */*\r\n" ++
        "\r\n" ++
        "Hi, it's body";
    const fake_addr = std.net.Address.initIp4(.{ 127, 0, 0, 1 }, 45944);
    var request = try Request.init(raw_request, allocator, false, fake_addr, false);

    std.debug.print("request created:", .{});
    request.fmt();
}
