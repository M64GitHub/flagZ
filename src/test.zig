const std = @import("std");
const flagz = @import("flagz.zig");

test "normal case - all fields set" {
    const Args = struct {
        name: []u8,
        count: usize,
        offset: isize,
        limit: u32,
        shift: i32,
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
            "-offset",
            "-10",
            "-limit",
            "1000",
            "-shift",
            "-500",
            "-verbose",
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
    defer flagz.deinit(args, allocator);

    try std.testing.expectEqualStrings("hello", args.name);
    try std.testing.expectEqual(@as(usize, 42), args.count);
    try std.testing.expectEqual(@as(isize, -10), args.offset);
    try std.testing.expectEqual(@as(u32, 1000), args.limit);
    try std.testing.expectEqual(@as(i32, -500), args.shift);
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

test "invalid int - non-numeric input for isize" {
    const Args = struct {
        name: []u8,
        offset: isize,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-name",
            "hello",
            "-offset",
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
        offset: isize,
        limit: u32,
        shift: i32,
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
    defer flagz.deinit(args, allocator);

    try std.testing.expectEqualStrings("", args.name);
    try std.testing.expectEqual(@as(usize, 0), args.count);
    try std.testing.expectEqual(@as(isize, 0), args.offset);
    try std.testing.expectEqual(@as(u32, 0), args.limit);
    try std.testing.expectEqual(@as(i32, 0), args.shift);
    try std.testing.expectEqual(false, args.verbose);
}

test "partial flags - some fields set" {
    const Args = struct {
        name: []u8,
        count: usize,
        offset: isize,
        limit: u32,
        shift: i32,
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
            "-offset",
            "-42",
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
    defer flagz.deinit(args, allocator);

    try std.testing.expectEqualStrings("hello", args.name);
    try std.testing.expectEqual(@as(usize, 0), args.count);
    try std.testing.expectEqual(@as(isize, -42), args.offset);
    try std.testing.expectEqual(@as(u32, 0), args.limit);
    try std.testing.expectEqual(@as(i32, 0), args.shift);
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
    defer flagz.deinit(args, allocator);

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
    defer flagz.deinit(args, allocator);

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
    defer flagz.deinit(args, allocator);

    try std.testing.expectEqualStrings("hello", args.name);
    try std.testing.expectEqual(@as(usize, 42), args.count);
}

test "multiple missing values - count and limit" {
    const Args = struct {
        name: []u8,
        count: usize,
        limit: u32,
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
            "-limit",
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

test "negative integer - invalid for usize" {
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
            "-42",
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
    try std.testing.expectError(error.NegativeValueNotAllowed, result);
}

test "negative integer - valid for isize" {
    const Args = struct {
        name: []u8,
        offset: isize,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-name",
            "hello",
            "-offset",
            "-42",
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
    defer flagz.deinit(args, allocator);

    try std.testing.expectEqualStrings("hello", args.name);
    try std.testing.expectEqual(@as(isize, -42), args.offset);
}

test "negative integer - invalid for u32" {
    const Args = struct {
        name: []u8,
        limit: u32,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-name",
            "hello",
            "-limit",
            "-1000",
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
    try std.testing.expectError(error.NegativeValueNotAllowed, result);
}

test "negative integer - valid for i32" {
    const Args = struct {
        name: []u8,
        shift: i32,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-name",
            "hello",
            "-shift",
            "-500",
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
    defer flagz.deinit(args, allocator);

    try std.testing.expectEqualStrings("hello", args.name);
    try std.testing.expectEqual(@as(i32, -500), args.shift);
}

test "duplicate flags - last value wins" {
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
            "-name",
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
    defer flagz.deinit(args, allocator);

    try std.testing.expectEqualStrings("world", args.name);
    try std.testing.expectEqual(@as(usize, 42), args.count);
}

test "overflow - usize too large" {
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
            "-count", "18446744073709551616", // 2^64, one past usize max
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
    try std.testing.expectError(error.Overflow, result);
}

test "overflow - isize too small" {
    const Args = struct {
        name: []u8,
        offset: isize,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-name",
            "hello",
            "-offset", "-9223372036854775809", // One past isize min
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
    try std.testing.expectError(error.Overflow, result);
}

test "overflow - u32 too large" {
    const Args = struct {
        name: []u8,
        limit: u32,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-name",
            "hello",
            "-limit", "4294967296", // One past u32 max
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
    try std.testing.expectError(error.Overflow, result);
}

test "overflow - i32 too large" {
    const Args = struct {
        name: []u8,
        shift: i32,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-name",
            "hello",
            "-shift", "2147483648", // One past i32 max
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
    try std.testing.expectError(error.Overflow, result);
}

test "overflow - i32 too small" {
    const Args = struct {
        name: []u8,
        shift: i32,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-name",
            "hello",
            "-shift", "-2147483649", // One past i32 min
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
    try std.testing.expectError(error.Overflow, result);
}
