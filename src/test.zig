const std = @import("std");
const flagz = @import("flagz.zig");

test "normal case - all fields set" {
    const Args = struct {
        name: []const u8,
        count: usize,
        verbose: bool,
        tag: [8]u8,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-name",
            "hello",
            "-count",
            "42",
            "--verbose",
            "-tag",
            "ziggy",
        };
        var list = try allocator.alloc([*:0]u8, args.len);
        for (args, 0..) |arg, i| {
            list[i] = @constCast(arg.ptr);
        }
        break :blk list;
    };
    defer allocator.free(argv);
    std.os.argv = @constCast(argv);

    const args = try flagz.parse(Args, allocator);
    defer flagz.deinit(Args, args, allocator);

    try std.testing.expectEqualStrings("hello", args.name);
    try std.testing.expectEqual(@as(usize, 42), args.count);
    try std.testing.expectEqual(true, args.verbose);
    try std.testing.expectEqual([8]u8{ 'z', 'i', 'g', 'g', 'y', 0, 0, 0 }, args.tag);
}

test "missing value - flag with no value" {
    const Args = struct {
        name: []u8,
        count: usize,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-name",
            "hello",
            "-count",
        };
        var list = try allocator.alloc([*:0]u8, args.len);
        for (args, 0..) |arg, i| {
            list[i] = @constCast(arg.ptr);
        }
        break :blk list;
    };
    defer allocator.free(argv);
    std.os.argv = @constCast(argv);

    const result = flagz.parse(Args, allocator);
    try std.testing.expectError(error.MissingValue, result);
}

test "invalid int - non-numeric input for usize" {
    const Args = struct {
        name: []u8,
        count: usize,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-name",
            "hello",
            "-count",
            "xxx",
        };
        var list = try allocator.alloc([*:0]u8, args.len);
        for (args, 0..) |arg, i| {
            list[i] = @constCast(arg.ptr);
        }
        break :blk list;
    };
    defer allocator.free(argv);
    std.os.argv = @constCast(argv);

    const result = flagz.parse(Args, allocator);
    try std.testing.expectError(error.InvalidIntValue, result);
}

test "string too long - [8]u8 field with >8 chars" {
    const Args = struct {
        tag: [8]u8,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-tag",
            "toolongstring",
        };
        var list = try allocator.alloc([*:0]u8, args.len);
        for (args, 0..) |arg, i| {
            list[i] = @constCast(arg.ptr);
        }
        break :blk list;
    };
    defer allocator.free(argv);
    std.os.argv = @constCast(argv);

    const result = flagz.parse(Args, allocator);
    try std.testing.expectError(error.StringTooLong, result);
}

test "no flags - empty input" {
    const Args = struct {
        name: []u8,
        count: usize,
        verbose: bool,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{"prog"};
        var list = try allocator.alloc([*:0]u8, args.len);
        for (args, 0..) |arg, i| {
            list[i] = @constCast(arg.ptr);
        }
        break :blk list;
    };
    defer allocator.free(argv);
    std.os.argv = @constCast(argv);

    const args = try flagz.parse(Args, allocator);
    defer flagz.deinit(Args, args, allocator);

    try std.testing.expectEqualStrings("", args.name);
    try std.testing.expectEqual(@as(usize, 0), args.count);
    try std.testing.expectEqual(false, args.verbose);
}

test "partial flags - some fields set" {
    const Args = struct {
        name: []u8,
        count: usize,
        verbose: bool,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-name",
            "hello",
        };
        var list = try allocator.alloc([*:0]u8, args.len);
        for (args, 0..) |arg, i| {
            list[i] = @constCast(arg.ptr);
        }
        break :blk list;
    };
    defer allocator.free(argv);
    std.os.argv = @constCast(argv);

    const args = try flagz.parse(Args, allocator);
    defer flagz.deinit(Args, args, allocator);

    try std.testing.expectEqualStrings("hello", args.name);
    try std.testing.expectEqual(@as(usize, 0), args.count);
    try std.testing.expectEqual(false, args.verbose);
}

test "multiple strings - all freed" {
    const Args = struct {
        name: []u8,
        title: []u8,
        count: usize,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-name",
            "hello",
            "-title",
            "world",
            "-count",
            "42",
        };
        var list = try allocator.alloc([*:0]u8, args.len);
        for (args, 0..) |arg, i| {
            list[i] = @constCast(arg.ptr);
        }
        break :blk list;
    };
    defer allocator.free(argv);
    std.os.argv = @constCast(argv);

    const args = try flagz.parse(Args, allocator);
    defer flagz.deinit(Args, args, allocator);

    try std.testing.expectEqualStrings("hello", args.name);
    try std.testing.expectEqualStrings("world", args.title);
    try std.testing.expectEqual(@as(usize, 42), args.count);
}

test "zero-length strings - empty input" {
    const Args = struct {
        name: []u8,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-name",
            "",
        };
        var list = try allocator.alloc([*:0]u8, args.len);
        for (args, 0..) |arg, i| {
            list[i] = @constCast(arg.ptr);
        }
        break :blk list;
    };
    defer allocator.free(argv);
    std.os.argv = @constCast(argv);

    const args = try flagz.parse(Args, allocator);
    defer flagz.deinit(Args, args, allocator);

    try std.testing.expectEqualStrings("", args.name);
}

test "invalid flag - ignored" {
    const Args = struct {
        name: []u8,
        count: usize,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-foo",
            "bar",
            "-name",
            "hello",
            "-count",
            "42",
        };
        var list = try allocator.alloc([*:0]u8, args.len);
        for (args, 0..) |arg, i| {
            list[i] = @constCast(arg.ptr);
        }
        break :blk list;
    };
    defer allocator.free(argv);
    std.os.argv = @constCast(argv);

    const args = try flagz.parse(Args, allocator);
    defer flagz.deinit(Args, args, allocator);

    try std.testing.expectEqualStrings("hello", args.name);
    try std.testing.expectEqual(@as(usize, 42), args.count);
}
