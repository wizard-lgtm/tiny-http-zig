# tiny-http-zig
## A simple http server inspired by tiny-http in rust

## Example:
```zig
pub fn to_http_string(self: *Response, do_not_send_body: bool) ![]const u8 {
    var buffer = std.ArrayList(u8).init(self.allocator);
    defer buffer.deinit();

    // Add status line
    try buffer.appendSlice(std.fmt.allocPrint(self.allocator, "HTTP/{}.{} {} {}\r\n", .{
        self.version.major,
        self.version.minor,
        self.status_code.code,
        self.status_code.message(),
    }));

    // Add headers
    for (self.headers.items) |header| {
        try buffer.appendSlice(std.fmt.allocPrint(self.allocator, "{}: {}\r\n", .{
            header.field,
            header.value,
        }));
    }

    // Add Content-Length header
    try buffer.appendSlice(std.fmt.allocPrint(self.allocator, "Content-Length: {}\r\n", .{
        if (do_not_send_body) 0 else self.body.len,
    }));

    // Add body
    if (!do_not_send_body) {
        try buffer.appendSlice("\r\n");
        try buffer.appendSlice(self.body);
    }

    return buffer.toOwnedSlice();
}
```

### Features

| Feature           | Status            |
|-------------------|-------------------|
| Parsing Request   | Implemented ✅     |
| Packing Responses | Implemented ✅     |
| JSON              | Not Implemented ❌ |
| Routing           | Future Planned 🎯  |

### Written with ziglang 0.12.0
### Supported zig versions
- 0.12.0



### Installation
- With zon

add to `build.zig.zon`

add to `build.zig`

### From locally

### Zigmod

### Contribution
1. Fork
2. Clone
3. Make a Test
4. Send the Pull Request
5. Success!

### License
This project licensed under MIT license (LICENSE-MIT or http://opensource.org/licenses/MIT)
