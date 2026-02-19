const std = @import("std");
// const print = std.debug.print;
// const expect = std.testing.expect;
// const eql = std.mem.eql;

pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer _ = gpa.deinit();
    // const allocator = gpa.allocator();

    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout: *std.io.Writer = &stdout_writer.interface;

    var stdin_buf: [1024]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buf);
    const stdin: *std.io.Reader = &stdin_reader.interface;

    while (true) {
        try stdout.writeAll("> ");
        try stdout.flush();

        const bare_line = try stdin.takeDelimiter('\n') orelse unreachable;
        const line = std.mem.trim(u8, bare_line, "\r");
        // const owned = try allocator.dupe(u8, line);
        // defer allocator.free(owned);
        try stdout.print("{s}\n", .{line});
        try stdout.flush();
    }
}
