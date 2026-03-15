const std = @import("std");

fn listDir(stdout: *std.io.Writer) !void {
    var dir =
        try std.fs.cwd().openDir(".", .{ .iterate = true });
    defer dir.close();
    var it = dir.iterate();
    while (try it.next()) |entry| {
        switch (entry.kind) {
            .directory => try stdout.print("{s}/\n", .{entry.name}),
            else => try stdout.print("{s}\n", .{entry.name}),
        }
    }
}

fn changeDir(line: []const u8, stdout: *std.io.Writer, allocator: std.mem.Allocator) !void {
    _ = allocator;

    if (line.len == 2) {
        try stdout.writeAll("Usage: cd <directory>\n");
        try stdout.flush();
    }

    var targetdir = std.mem.trim(u8, line[3..], " ");
    if (targetdir.len >= 2) {
        if ((targetdir[0] == '"' and targetdir[targetdir.len - 1] == '"') or
            (targetdir[0] == '\'' and targetdir[targetdir.len - 1] == '\''))
        {
            targetdir = targetdir[1 .. targetdir.len - 1];
        }
    }

    var target_d = std.fs.cwd().openDir(targetdir, .{}) catch |err| {
        try stdout.print("cd: cannot access '{s}': {}\n", .{ targetdir, err });
        try stdout.flush();
        return;
    };

    defer target_d.close();

    target_d.setAsCwd() catch |err| {
        try stdout.print("cd: failed to change directory: {}\n", .{err});
        try stdout.flush();
        return;
    };

    try stdout.flush();
}

fn removeFile(line: []const u8, stdout: *std.io.Writer, allocator: std.mem.Allocator) !void {
    _ = allocator;

    const target = std.mem.trim(u8, line[3..], " ");

    if (target.len == 0) {
        try stdout.writeAll("Usage: rm<file|directory>\n");
        try stdout.flush();
        return;
    }

    var path = target;
    if (path.len >= 2) {
        if ((path[0] == '"' and path[path.len - 1] == '"') or
            (path[0] == '\'' and path[path.len - 1] == '\''))
        {
            path = path[1 .. path.len - 1];
        }
    }

    std.fs.cwd().deleteFile(path) catch {
        std.fs.cwd().deleteDir(path) catch {
            std.fs.cwd().deleteTree(path) catch |errTree| {
                try stdout.print("rm: cannot remove '{s}': {}\n", .{ path, errTree });
                try stdout.flush();
                return;
            };
        };
    };
    try stdout.flush();
}

fn runScripts(stdout: *std.io.Writer, allocator: std.mem.Allocator) !void {
    var child = std.process.Child.init(&[_][]const u8{
        "powershell",
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        "scripts.ps1",
    }, allocator);

    _ = child.spawnAndWait() catch |err| {
        try stdout.print("failed to run scripts; {}\n", .{err});
        try stdout.flush();
        return;
    };

    try stdout.flush();
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
        const dir = try std.process.getCwdAlloc(allocator);
        defer allocator.free(dir);

        try stdout.print("{s}> ", .{dir});
        try stdout.flush();

        const bare_line = try stdin.takeDelimiter('\n') orelse break;
        const line = std.mem.trim(u8, bare_line, "\r");

        if (std.mem.eql(u8, line, "exit")) {
            try stdout.writeAll("bye!\n");
            try stdout.flush();
            break;
        }

        if (std.mem.eql(u8, line, "ls")) {
            try listDir(stdout);
            try stdout.flush();
            continue;
        }

        if (std.mem.eql(u8, line, "cls") or std.mem.eql(u8, line, "clear")) {
            try stdout.writeAll("\x1b[2J\x1b[H"); // ANSI escape sequence
            try stdout.flush();
            continue;
        }

        if (std.mem.eql(u8, line, "pwd")) {
            const cwd = try std.process.getCwdAlloc(allocator);
            defer allocator.free(cwd);

            try stdout.print("{s}\n", .{cwd});
            try stdout.flush();
            continue;
        }

        if (std.mem.startsWith(u8, line, "cd")) {
            try changeDir(line, stdout, allocator);
            continue;
        }

        if (std.mem.startsWith(u8, line, "rm")) {
            try removeFile(line, stdout, allocator);
            continue;
        }

        if (std.mem.startsWith(u8, line, "echo")) {
            var text = line[5..];

            if (text.len >= 2) {
                if ((text[0] == '"' and text[text.len - 1] == '"') or
                    (text[0] == '\'' and text[text.len - 1] == '\''))
                {
                    text = text[1 .. text.len - 1];
                }
            }

            var iter = std.mem.splitScalar(u8, text, ' ');
            while (iter.next()) |word| {
                if (word.len > 0) {
                    try stdout.print("{s}\n", .{word});
                }
            }

            try stdout.flush();
            continue;
        }

        if (std.mem.eql(u8, line, "help")) {
            var child = std.process.Child.init(&[_][]const u8{"help"}, allocator);
            _ = try child.spawnAndWait();

            try stdout.flush();
            continue;
        }

        if (std.mem.eql(u8, line, "?")) {
            const file = try std.fs.cwd().openFile("help.txt", .{});
            defer file.close();

            const content = try file.readToEndAlloc(allocator, 4096);
            defer allocator.free(content);

            try stdout.writeAll(content);
            try stdout.flush();
            continue;
        }

        if (std.mem.eql(u8, line, "reshell")) {
            try runScripts(stdout, allocator);
            continue;
        }

        if (line.len == 0) continue;

        var child = std.process.Child.init(&[_][]const u8{line}, allocator);
        child.spawn() catch |err| {
            if (err == error.FileNotFound) {
                try stdout.print("'{s}' is not recognized as an internal or external command,\noperable program or batch file.\n", .{line});
            }

            try stdout.flush();
            continue;
        };
        _ = try child.wait();
    }
}
