const std = @import("std");

pub fn len_hashmap_contents(hashmap: std.StringHashMap([]const u8)) u64 {
    var total: u64 = 0;
    var it = hashmap.iterator();

    while (it.next()) |entry| {
        total += entry.key_ptr.len + entry.value_ptr.len;
    }

    return total;
}

pub fn concat_strings(allocator: std.mem.Allocator, dest: *[]u8, src: []const u8) !void {
    const old_len = dest.len;
    const new_len = old_len + src.len;
    dest.* = try allocator.realloc(dest.*, new_len);

    // @memcpy'yi doğru adreslerle çağır
    @memcpy(dest.*[old_len..new_len], src);
}

pub fn chop_n(buffer: *[]u8, n: u16, allocator: std.mem.Allocator) ![]u8 {
    const len = buffer.*.len;

    defer allocator.free(buffer.*);

    if (len < n) {
        const new_buffer = try allocator.alloc(u8, 0);
        return new_buffer;
    }

    const new_len = buffer.len - n;

    var new_buffer = try allocator.alloc(u8, new_len);
    @memcpy(new_buffer[0..], buffer.*[n..]);

    return new_buffer;
}
