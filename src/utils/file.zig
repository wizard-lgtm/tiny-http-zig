const std = @import("std");

pub fn getFileSize(file_path: []const u8) !u64 {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();
    const stats = try file.stat();
    return stats.size;
}

/// Read all the file contents to buffer. Returns FileTooBig error if file size is bigger than buffer size.
pub fn read_file(file_path: []const u8, allocator: std.mem.Allocator) ![]u8 {

    // Get file size
    const file_size = try getFileSize(file_path);

    // Alloc the buffer
    const buffer = try allocator.alloc(u8, file_size);

    // Check if file exist
    if (try is_file_exist(file_path) == false) {
        std.debug.print("File not found at: {any}", .{file_path});
        return error.FileNotFound;
    }

    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    _ = try file.readAll(buffer);

    return buffer;
}

/// Check if file exists, returns true if file exist.
pub fn is_file_exist(file_path: []const u8) !bool {
    _ = std.fs.cwd().statFile(file_path) catch |err| {
        switch (err) {
            error.FileNotFound => return false,
            else => return err,
        }
    };
    return true;
}

pub fn delete_file_contents(file_path: []const u8) !void {
    const file = try std.fs.cwd().openFile(file_path, .{ .mode = std.fs.File.OpenMode.write_only });
    defer file.close();

    _ = try file.setEndPos(0);
}

/// Writes whole buffer to file, creates file if it not exists
pub fn write_buffer_to_file(
    file_path: []const u8,
    buffer: []const u8,
) !void {
    const file_exists = try is_file_exist(file_path);

    // Create file if it's not exists
    if (!file_exists) {
        _ = try std.fs.cwd().createFile(file_path, .{});
    }
    var file = try std.fs.cwd().openFile(file_path, .{ .mode = std.fs.File.OpenMode.write_only });
    defer file.close();

    _ = try file.writeAll(buffer);

    std.debug.print("Contents written to file {s}\n", .{file_path});
}

pub const EntryInfo = struct {
    name: []const u8,
    is_dir: bool,
};

pub fn list_dir_contents(path: []const u8, allocator: std.mem.Allocator) !std.ArrayList(EntryInfo) {
    var dir = try std.fs.cwd().openDir(path, .{});
    defer dir.close();

    var list = std.ArrayList(EntryInfo).init(allocator);

    var it = dir.iterate();
    while (try it.next()) |entry| {
        const is_dir = entry.kind == std.fs.File.Kind.directory;

        // Copy entry name
        const name = try allocator.alloc(u8, entry.name.len);
        @memcpy(name[0..entry.name.len], entry.name);

        try list.append(EntryInfo{ .name = name, .is_dir = is_dir });
    }

    return list;
}
