const std = @import("std");
const flagz = @import("flagz");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const Args = struct {
        count: ?usize, // null if unset
        verbose: bool, // false if unset
    };

    const args = try flagz.parse(Args, allocator);
    defer flagz.deinit(args, allocator);
    if (args.count) |c| std.debug.print("Count set: {}\n", .{c}) else std.debug.print("Count unset\n", .{});
    std.debug.print("Verbose: {}\n", .{args.verbose});
}
