const std = @import("std");
const flagz = @import("flagz");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const Args = struct {
        name: []u8,
        count: usize,
        verbose: bool,
        tag: [8]u8,
    };

    const args = try flagz.parse(Args, allocator);
    defer args.deinit();

    std.debug.print("Name: {s}\n", .{args.name});
    std.debug.print("Count: {}\n", .{args.count});
    std.debug.print("Verbose: {} (flags revolution begins!)\n", .{args.verbose});
    std.debug.print("Tag: {s}\n", .{args.tag});
}
