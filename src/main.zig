const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){}; // allocator object
    defer _ = gpa.deinit(); // free memory
    // const allocator = gpa.allocator();
}