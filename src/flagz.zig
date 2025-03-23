const std = @import("std");

pub const Error = error{
    MissingValue,
    StringTooLong,
    InvalidIntValue,
    NegativeValueNotAllowed,
};

pub fn parse(comptime T: type, allocator: std.mem.Allocator) !T {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    var result: T = undefined;

    const args = try std.process.argsAlloc(arena_allocator);
    defer std.process.argsFree(arena_allocator, args);

    errdefer inline for (std.meta.fields(T)) |field| {
        if (@typeInfo(field.type) == .pointer and (field.type == []u8 or field.type == []const u8) and @field(result, field.name).len > 0) {
            allocator.free(@field(result, field.name));
        }
    };

    var arg_index: usize = 1;

    const fields = std.meta.fields(T);

    inline for (fields) |field| {
        switch (@typeInfo(field.type)) {
            .bool => @field(result, field.name) = false,
            .int => @field(result, field.name) = 0,
            .array => |arr| if (arr.child == u8) {
                @field(result, field.name) = [_]u8{0} ** arr.len;
            },
            .pointer => |ptr| if (ptr.child == u8) {
                @field(result, field.name) = "";
            },
            else => @compileError("Unsupported field type: " ++ @typeName(field.type)),
        }
    }

    while (arg_index < args.len) : (arg_index += 1) {
        const arg = args[arg_index];
        if (arg.len <= 1 or arg[0] != '-') continue;

        const flag_name = arg[1..];
        inline for (fields) |field| {
            const field_name = field.name;

            if (std.mem.eql(u8, flag_name, field_name)) {
                switch (@typeInfo(field.type)) {
                    .bool => {
                        @field(result, field.name) = true;
                    },
                    .int => |_| {
                        if (arg_index + 1 >= args.len) return error.MissingValue;
                        const next_arg = args[arg_index + 1];
                        if (next_arg.len > 1 and next_arg[0] == '-' and std.ascii.isAlphabetic(next_arg[1])) {
                            return error.MissingValue;
                        }
                        const value = next_arg;
                        const parsed = std.fmt.parseInt(i64, value, 10) catch |err| switch (err) {
                            error.InvalidCharacter => return error.InvalidIntValue,
                            else => return err,
                        };
                        if (parsed < 0 and @typeInfo(field.type).int.signedness == .unsigned) {
                            return error.NegativeValueNotAllowed;
                        }
                        @field(result, field.name) = std.math.cast(field.type, parsed) orelse return error.Overflow;
                        arg_index += 1;
                    },
                    .pointer => |ptr| if (ptr.child == u8) {
                        if (arg_index + 1 >= args.len) return error.MissingValue;
                        const next_arg = args[arg_index + 1];
                        if (next_arg.len > 1 and next_arg[0] == '-' and std.ascii.isAlphabetic(next_arg[1])) {
                            return error.MissingValue;
                        }
                        const value = next_arg;
                        if (@field(result, field.name).len > 0) {
                            allocator.free(@field(result, field.name));
                        }
                        const copied = try allocator.dupe(u8, value);
                        @field(result, field.name) = copied;
                        arg_index += 1;
                    },
                    .array => |arr| if (arr.child == u8) {
                        if (arg_index + 1 >= args.len) return error.MissingValue;
                        const next_arg = args[arg_index + 1];
                        if (next_arg.len > 1 and next_arg[0] == '-' and std.ascii.isAlphabetic(next_arg[1])) {
                            return error.MissingValue;
                        }
                        const value = next_arg;
                        if (value.len > arr.len) return error.StringTooLong;
                        @memcpy(@field(result, field.name)[0..value.len], value);
                        arg_index += 1;
                    },
                    else => @compileError("Unsupported field type: " ++ @typeName(field.type)),
                }
            }
        }
    }

    return result;
}

pub fn deinit(args: anytype, allocator: std.mem.Allocator) void {
    const fields = std.meta.fields(@TypeOf(args));
    inline for (fields) |field| {
        if (@typeInfo(field.type) == .pointer and
            (field.type == []u8 or field.type == []const u8))
        {
            if (@field(args, field.name).len > 0) {
                allocator.free(@field(args, field.name));
            }
        }
    }
}
