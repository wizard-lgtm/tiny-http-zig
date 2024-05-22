const std = @import("std");
const utils = @import("./utils/uuid.zig");

pub fn main() !void {
    const id = utils.generate_uuid();
    std.debug.print("HI {s}\n", .{id.*});
}
