const std = @import("std");
const flagz = @import("flagz");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const Args = struct {
        name: []const u8,
        count: usize, // Unsigned, no negatives allowed
        offset: isize, // Signed, allows negatives
        limit: u32, // Smaller unsigned, 0 to 2^32 - 1
        shift: i32, // Smaller signed, -2^31 to 2^31 - 1
        verbose: bool,
        tag: [8]u8,
    };

    const args = try flagz.parse(Args, allocator);
    defer flagz.deinit(args, allocator);

    std.debug.print("Name: {s}\n", .{args.name});
    std.debug.print("Count (usize): {}\n", .{args.count});
    std.debug.print("Offset (isize): {}\n", .{args.offset});
    std.debug.print("Limit (u32): {}\n", .{args.limit});
    std.debug.print("Shift (i32): {}\n", .{args.shift});
    std.debug.print("Verbose: {}\n", .{args.verbose});
    std.debug.print("Tag: {s}\n", .{args.tag});
}
