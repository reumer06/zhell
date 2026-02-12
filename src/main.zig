const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
    @cInclude("string.h");
    @cInclude("time.h");
    @cInclude("sys/wait.h");
});

pub fn main() void {
    _ = c.printf("the code is this\n");
}