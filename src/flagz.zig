const std = @import("std");

pub const version = "1.1.0";

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
        switch (@typeInfo(field.type)) {
            .optional => |opt| {
                const child_type = opt.child;
                if (@typeInfo(child_type) == .pointer and
                    (child_type == []u8 or child_type == []const u8))
                {
                    if (@field(result, field.name)) |val| {
                        if (val.len > 0) allocator.free(val);
                    }
                }
            },
            .pointer => |ptr| if (ptr.child == u8 and
                @field(result, field.name).len > 0)
            {
                allocator.free(@field(result, field.name));
            },
            else => {},
        }
    };

    var arg_index: usize = 1;

    const fields = std.meta.fields(T);

    inline for (fields) |field| {
        switch (@typeInfo(field.type)) {
            .optional => |opt| switch (@typeInfo(opt.child)) {
                .bool => @field(result, field.name) = null,
                .int => @field(result, field.name) = null,
                .float => @field(result, field.name) = null,
                .array => |arr| if (arr.child == u8) {
                    @field(result, field.name) = null;
                },
                .pointer => |ptr| if (ptr.child == u8) {
                    @field(result, field.name) = null;
                },
                else => @compileError("Unsupported optional child type: " ++
                    @typeName(opt.child)),
            },
            .bool => @field(result, field.name) = false,
            .int => @field(result, field.name) = 0,
            .float => @field(result, field.name) = 0.0,
            .array => |arr| if (arr.child == u8) {
                @field(result, field.name) = [_]u8{0} ** arr.len;
            },
            .pointer => |ptr| if (ptr.child == u8) {
                @field(result, field.name) = "";
            },
            else => @compileError("Unsupported field type: " ++
                @typeName(field.type)),
        }
    }

    while (arg_index < args.len) : (arg_index += 1) {
        const arg = args[arg_index];
        if (arg.len <= 1 or arg[0] != '-') continue;

        const flag_name = arg[1..];
        inline for (fields) |field| {
            if (std.mem.eql(u8, flag_name, field.name) or
                (flag_name.len < field.name.len and
                    std.mem.startsWith(u8, field.name, flag_name)))
            {
                switch (@typeInfo(field.type)) {

                    // -- optional

                    .optional => |opt| switch (@typeInfo(opt.child)) {
                        .bool => {
                            @field(result, field.name) = true;
                        },

                        .int => |_| {
                            if (arg_index + 1 >= args.len) return error.MissingValue;
                            const next_arg = args[arg_index + 1];
                            if (next_arg.len > 1 and next_arg[0] == '-' and
                                std.ascii.isAlphabetic(next_arg[1]))
                            {
                                return error.MissingValue;
                            }
                            const value = next_arg;
                            if (@typeInfo(
                                opt.child,
                            ).int.signedness == .unsigned and
                                value.len > 0 and value[0] == '-')
                            {
                                return error.NegativeValueNotAllowed;
                            }
                            @field(result, field.name) = std.fmt.parseInt(
                                opt.child,
                                value,
                                10,
                            ) catch |err| switch (err) {
                                error.InvalidCharacter => return error.InvalidIntValue,
                                error.Overflow => return error.Overflow,
                                else => return err,
                            };
                            arg_index += 1;
                        },

                        .float => |_| {
                            if (arg_index + 1 >= args.len)
                                return error.MissingValue;
                            const next_arg = args[arg_index + 1];
                            if (next_arg.len > 1 and next_arg[0] == '-' and
                                std.ascii.isAlphabetic(next_arg[1]))
                            {
                                return error.MissingValue;
                            }
                            const value = next_arg;
                            const parsed = std.fmt.parseFloat(
                                opt.child,
                                value,
                            ) catch |err| switch (err) {
                                error.InvalidCharacter => return error.InvalidIntValue,
                                else => return err,
                            };
                            if (std.math.isInf(parsed))
                                return error.Overflow;
                            @field(result, field.name) = parsed;
                            arg_index += 1;
                        },

                        .pointer => |ptr| if (ptr.child == u8) {
                            if (arg_index + 1 >= args.len)
                                return error.MissingValue;
                            const next_arg = args[arg_index + 1];
                            if (next_arg.len > 1 and next_arg[0] == '-' and
                                std.ascii.isAlphabetic(next_arg[1]))
                            {
                                return error.MissingValue;
                            }
                            const value = next_arg;
                            if (@field(result, field.name)) |old_val| {
                                if (old_val.len > 0) allocator.free(old_val);
                            }
                            @field(result, field.name) = try allocator.dupe(
                                u8,
                                value,
                            );
                            arg_index += 1;
                        },

                        .array => |arr| if (arr.child == u8) {
                            if (arg_index + 1 >= args.len)
                                return error.MissingValue;
                            const next_arg = args[arg_index + 1];
                            if (next_arg.len > 1 and next_arg[0] == '-' and
                                std.ascii.isAlphabetic(next_arg[1]))
                            {
                                return error.MissingValue;
                            }
                            const value = next_arg;
                            if (value.len > arr.len) return error.StringTooLong;
                            var array: [arr.len]u8 = undefined;
                            @memcpy(array[0..value.len], value);
                            @field(result, field.name) = array;
                            arg_index += 1;
                        },

                        else => @compileError(
                            "Unsupported optional child type: " ++
                                @typeName(opt.child),
                        ),
                    },

                    // -- non-optional

                    .bool => {
                        @field(result, field.name) = true;
                    },

                    .int => |_| {
                        if (arg_index + 1 >= args.len) return error.MissingValue;
                        const next_arg = args[arg_index + 1];
                        if (next_arg.len > 1 and next_arg[0] == '-' and
                            std.ascii.isAlphabetic(next_arg[1]))
                        {
                            return error.MissingValue;
                        }
                        const value = next_arg;
                        if (@typeInfo(
                            field.type,
                        ).int.signedness == .unsigned and value.len > 0 and
                            value[0] == '-')
                        {
                            return error.NegativeValueNotAllowed;
                        }
                        @field(result, field.name) = std.fmt.parseInt(
                            field.type,
                            value,
                            10,
                        ) catch |err| switch (err) {
                            error.InvalidCharacter => return error.InvalidIntValue,
                            error.Overflow => return error.Overflow,
                            else => return err,
                        };
                        arg_index += 1;
                    },

                    .float => |_| {
                        if (arg_index + 1 >= args.len) return error.MissingValue;
                        const next_arg = args[arg_index + 1];
                        if (next_arg.len > 1 and next_arg[0] == '-' and
                            std.ascii.isAlphabetic(next_arg[1]))
                        {
                            return error.MissingValue;
                        }
                        const value = next_arg;
                        const parsed = std.fmt.parseFloat(
                            field.type,
                            value,
                        ) catch |err| switch (err) {
                            error.InvalidCharacter => return error.InvalidIntValue,
                            else => return err,
                        };
                        if (std.math.isInf(parsed)) return error.Overflow;
                        @field(result, field.name) = parsed;
                        arg_index += 1;
                    },

                    .pointer => |ptr| if (ptr.child == u8) {
                        if (arg_index + 1 >= args.len)
                            return error.MissingValue;
                        const next_arg = args[arg_index + 1];
                        if (next_arg.len > 1 and next_arg[0] == '-' and
                            std.ascii.isAlphabetic(next_arg[1]))
                        {
                            return error.MissingValue;
                        }
                        const value = next_arg;
                        if (@field(result, field.name).len > 0) {
                            allocator.free(@field(result, field.name));
                        }
                        @field(
                            result,
                            field.name,
                        ) = try allocator.dupe(u8, value);
                        arg_index += 1;
                    },

                    .array => |arr| if (arr.child == u8) {
                        if (arg_index + 1 >= args.len) return error.MissingValue;
                        const next_arg = args[arg_index + 1];
                        if (next_arg.len > 1 and next_arg[0] == '-' and
                            std.ascii.isAlphabetic(next_arg[1]))
                        {
                            return error.MissingValue;
                        }
                        const value = next_arg;
                        if (value.len > arr.len) return error.StringTooLong;
                        @memcpy(@field(result, field.name)[0..value.len], value);
                        arg_index += 1;
                    },

                    else => @compileError("Unsupported field type: " ++
                        @typeName(field.type)),
                }
                break;
            }
        }
    }

    return result;
}

pub fn deinit(args: anytype, allocator: std.mem.Allocator) void {
    const fields = std.meta.fields(@TypeOf(args));
    inline for (fields) |field| {
        switch (@typeInfo(field.type)) {
            .optional => |opt| {
                const child_type = opt.child;
                if (@typeInfo(child_type) == .pointer and
                    (child_type == []u8 or child_type == []const u8))
                {
                    if (@field(args, field.name)) |val| {
                        if (val.len > 0) allocator.free(val);
                    }
                }
            },
            .pointer => |ptr| if (ptr.child == u8 and
                @field(args, field.name).len > 0)
            {
                allocator.free(@field(args, field.name));
            },
            else => {},
        }
    }
}
