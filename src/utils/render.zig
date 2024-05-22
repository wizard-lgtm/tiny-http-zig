const std = @import("std");
const file_utils = @import("./file.zig");
pub fn render_template(file_path: []const u8, allocator: std.mem.Allocator, data: ?std.StringHashMap([]const u8)) ![]const u8 {
    const html_string = try file_utils.read_file(file_path, allocator);

    const script_head = "<script>\n";
    const script_end = "</script>\n";

    var buffer = try allocator.alloc(u8, 0);

    _ = try file_utils.concat_strings(allocator, &buffer, script_head);

    if (data) |data_unwrapped| {
        // Append data to script
        var it = data_unwrapped.iterator();

        while (it.next()) |entry| {
            const js_str = try std.fmt.allocPrint(
                allocator,
                "let {s} = `{s}`;\n",
                .{ entry.key_ptr.*, entry.value_ptr.* },
            );

            _ = try file_utils.concat_strings(allocator, &buffer, js_str);
        }
    }

    _ = try file_utils.concat_strings(allocator, &buffer, script_end);
    _ = try file_utils.concat_strings(allocator, &buffer, html_string);

    return buffer;
}
