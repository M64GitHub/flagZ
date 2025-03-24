const std = @import("std");
const flagz = @import("flagz.zig");

test "normal case - all fields set" {
    const Args = struct {
        name: []u8,
        count: usize,
        offset: isize,
        limit: u32,
        shift: i32,
        temp: f32,
        rate: f64,
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
            "-temp",
            "23.5",
            "-rate",
            "0.001",
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
    try std.testing.expectEqual(@as(f32, 23.5), args.temp);
    try std.testing.expectEqual(@as(f64, 0.001), args.rate);
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
        offset: isize,
        limit: u32,
        shift: i32,
        temp: f32,
        rate: f64,
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
    try std.testing.expectEqual(@as(f32, 0.0), args.temp);
    try std.testing.expectEqual(@as(f64, 0.0), args.rate);
    try std.testing.expectEqual(false, args.verbose);
}

test "partial flags - some fields set" {
    const Args = struct {
        name: []u8,
        count: usize,
        offset: isize,
        limit: u32,
        shift: i32,
        temp: f32,
        rate: f64,
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
            "-temp",
            "3.14",
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
    try std.testing.expectEqual(@as(f32, 3.14), args.temp);
    try std.testing.expectEqual(@as(f64, 0.0), args.rate);
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

test "invalid float - non-numeric input for f32" {
    const Args = struct {
        name: []u8,
        temp: f32,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-name",
            "hello",
            "-temp",
            "xyz",
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

test "overflow - f64 too large" {
    const Args = struct {
        name: []u8,
        rate: f64,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-name",
            "hello",
            "-rate", "1e309", // Beyond f64 max (~1.8e308)
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
    if (result) |args| flagz.deinit(args, allocator) else |_| {} // No semicolon here!
    try std.testing.expectError(error.Overflow, result);
}

test "single dash - ignored" {
    const Args = struct {
        name: []u8,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-",
            "value",
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
    defer flagz.deinit(args, allocator);

    try std.testing.expectEqualStrings("hello", args.name);
}

test "empty flag name - ignored" {
    const Args = struct {
        name: []u8,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "--",
            "value",
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
    defer flagz.deinit(args, allocator);

    try std.testing.expectEqualStrings("hello", args.name);
}

test "zero-length value after flag - invalid" {
    const Args = struct {
        count: usize,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-count",
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

    const result = flagz.parse(Args, allocator);
    try std.testing.expectError(error.InvalidIntValue, result);
}

test "whitespace-only string" {
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
            "  ",
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

    try std.testing.expectEqualStrings("  ", args.name);
}

test "smallest non-zero f32" {
    const Args = struct {
        temp: f32,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-temp", "1.4e-45", // Smallest positive f32
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

    try std.testing.expectEqual(@as(f32, 1.4e-45), args.temp);
}

test "multiple same-type flags - last wins" {
    const Args = struct {
        count: usize,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-count",
            "1",
            "-count",
            "2",
            "-count",
            "3",
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

    try std.testing.expectEqual(@as(usize, 3), args.count);
}

test "mixed valid and invalid flags" {
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
            "-count",   "xyz", // Invalid
            "-verbose",
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

test "huge string allocation" {
    const Args = struct {
        name: []u8,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const huge_string = "a" ** 1024; // 1KB string
    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-name",
            huge_string,
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

    try std.testing.expectEqualStrings(huge_string, args.name);
}

test "negative zero float" {
    const Args = struct {
        temp: f32,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-temp",
            "-0.0",
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

    try std.testing.expectEqual(@as(f32, -0.0), args.temp);
}

test "short flag overlap - first match wins" {
    const Args = struct {
        name: []u8,
        number: usize,
        note: bool,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-n",
            "hello",
            "-number",
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
    try std.testing.expectEqual(@as(usize, 42), args.number);
    try std.testing.expectEqual(false, args.note);
}

test "trailing args after flags - ignored" {
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
            "hello",
            "foo",
            "bar",
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
}

test "empty argv - defaults only" {
    const Args = struct {
        name: []u8,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{};
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

test "optional field unset" {
    const Args = struct {
        count: ?usize,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
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

    try std.testing.expectEqual(null, args.count);
}

test "optional field set" {
    const Args = struct {
        count: ?usize,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
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

    try std.testing.expectEqual(@as(?usize, 42), args.count);
}

test "non-optional field unset" {
    const Args = struct {
        count: usize,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
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

    try std.testing.expectEqual(@as(usize, 0), args.count);
}

test "non-optional field set" {
    const Args = struct {
        count: usize,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
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

    try std.testing.expectEqual(@as(usize, 42), args.count);
}

test "mixed optional and non-optional fields" {
    const Args = struct {
        count: ?usize, // Optional
        verbose: bool, // Non-optional
        name: ?[]u8, // Optional
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
            "-verbose",
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
    defer flagz.deinit(args, allocator);

    try std.testing.expectEqual(null, args.count); // Unset optional
    try std.testing.expectEqual(true, args.verbose); // Set non-optional
    try std.testing.expectEqualStrings("hello", args.name.?); // Set optional
}

test "optional string unset" {
    const Args = struct {
        name: ?[]u8,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
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

    try std.testing.expectEqual(null, args.name);
}

test "optional string set" {
    const Args = struct {
        name: ?[]u8,
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
    defer flagz.deinit(args, allocator);

    try std.testing.expectEqualStrings("hello", args.name.?);
}

test "non-optional string unset" {
    const Args = struct {
        name: []u8,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
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

test "non-optional string set" {
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
    defer flagz.deinit(args, allocator);

    try std.testing.expectEqualStrings("hello", args.name);
}

test "non-optional array string unset" {
    const Args = struct {
        tag: [8]u8,
    };

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const argv = blk: {
        const args = [_][:0]const u8{
            "prog",
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

    try std.testing.expectEqual([8]u8{ 0, 0, 0, 0, 0, 0, 0, 0 }, args.tag);
}

test "non-optional array string set" {
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

    try std.testing.expectEqual([8]u8{ 'z', 'i', 'g', 'g', 'y', 0, 0, 0 }, args.tag);
}
