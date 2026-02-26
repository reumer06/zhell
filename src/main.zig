const std = @import("std");

fn listDir(stdout : *std.io.Writer) !void {     
    var dir = 
    try std.fs.cwd().openDir(".",.{.iterate = true});
    defer dir.close();
    var it = dir.iterate();
    while(try it.next()) |entry| {
        switch (entry.kind) { 
            .directory  => 
            try stdout.print("{s}/\n",.{entry.name}),
            else => try stdout.print("{s}\n",.{entry.name})
        }
    }
}

pub fn main() !void {

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

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

        if (std.mem.eql(u8,line,"ls")) {
            try listDir(stdout);
            try stdout.flush();
            continue;
        }

        if (std.mem.eql(u8, line, "cls") or std.mem.eql(u8, line, "clear")) {
            try stdout.writeAll("\x1b[2J\x1b[H"); // ANSI escape sequence
            try stdout.flush();
            continue;
        }

        if (std.mem.eql(u8,line,"pwd")) {
            const cwd = try std.process.getCwdAlloc(allocator);
            defer allocator.free(cwd);

            try stdout.print("{s}\n",.{cwd});
            try stdout.flush();
            continue;
        }

        if (std.mem.startsWith(u8,line, "echo")) {
            var text = line[5..];

            if (text.len >= 2) {
                if ((text[0] == '"' and text[text.len - 1] == '"') or 
                    (text[0] == '\'' and text[text.len - 1] == '\'')) {
                        text = text[1..text.len - 1];
                }
            }
            
            try stdout.print("{s}\n",.{text});
            try stdout.flush();
            continue;
        }

        if (line.len == 0) continue;

        var child = std.process.Child.init(&[_][]const u8{line},allocator);
        child.spawn() catch |err|{
        if(err == error.FileNotFound) {
            try stdout.print("'{s}' is not recognized as an internal or external command,\noperable program or batch file.\n", .{line});
            }
            try stdout.flush();
            continue;
        };
        _ = try child.wait();
    }
}
