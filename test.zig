const std = @import("std");
const common = @import("./src/common.zig");
const Header = common.Header;

test "test strict headers" {
    const e = error.InvalidHeader;

    _ = e;

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
