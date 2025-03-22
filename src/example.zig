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

    std.debug.print("Name: {s}\n", .{args.values.name});
    std.debug.print("Count: {}\n", .{args.values.count});
    std.debug.print("Verbose: {}\n", .{args.values.verbose});
    std.debug.print("Tag: {s}\n", .{args.values.tag});
}
