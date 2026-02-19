const std = @import("std");

pub fn main() !void {
    const stdout_file = std.fs.File.stdout();
    _ = stdout_file.getOrEnableAnsiEscapeSupport();

    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout: *std.io.Writer = &stdout_writer.interface;

    var stdin_buf: [1024]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buf);
    const stdin: *std.io.Reader = &stdin_reader.interface;

    while (true) {
        try stdout.writeAll("> ");
        try stdout.flush();

        const bare_line = try stdin.takeDelimiter('\n') orelse break;
        const line = std.mem.trim(u8, bare_line, "\r");

        if (std.mem.eql(u8, line, "exit")) {
            try stdout.writeAll("bye!\n");
            try stdout.flush();
            break;
        }

        if (std.mem.eql(u8, line, "cls") or std.mem.eql(u8, line, "clear")) {
            try stdout.writeAll("\x1b[2J\x1b[H"); // ANSI escape sequence
            try stdout.flush();
            continue;
        }

        try stdout.print("{s}\n", .{line});
        try stdout.flush();
    }
}
