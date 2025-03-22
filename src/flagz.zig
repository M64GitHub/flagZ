const std = @import("std");

pub const Error = error{
    MissingValue,
    StringTooLong,
    InvalidIntValue, // New custom error
};

pub fn parse(comptime T: type, allocator: std.mem.Allocator) !T {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    var result: T = undefined;

    const args = try std.process.argsAlloc(arena_allocator);
    defer std.process.argsFree(arena_allocator, args);

    var arg_index: usize = 1;

    const fields = std.meta.fields(T);

    inline for (fields) |field| {
        switch (@typeInfo(field.type)) {
            .Bool => @field(result, field.name) = false,
            .Int => @field(result, field.name) = 0,
            .Array => |arr| if (arr.child == u8) {
                @field(result, field.name) = [_]u8{0} ** arr.len;
            },
            .Pointer => |ptr| if (ptr.child == u8) {
                @field(result, field.name) = "";
            },
            else => @compileError("Unsupported field type: " ++ @typeName(field.type)),
        }
    }

    while (arg_index < args.len) : (arg_index += 1) {
        const arg = args[arg_index];
        if (arg.len > 1 and arg[0] == '-') {
            const flag_name = arg[1..];
            inline for (fields) |field| {
                const field_name = if (field.name[0] == '.') field.name[1..] else field.name;

                if (std.mem.eql(u8, flag_name, field_name)) {
                    switch (@typeInfo(field.type)) {
                        .Bool => {
                            @field(result, field.name) = true;
                        },
                        .Int => |_| {
                            if (arg_index + 1 >= args.len) {
                                inline for (fields) |f| {
                                    if (@typeInfo(f.type) == .Pointer and f.type == []u8 and @field(result, f.name).len > 0) {
                                        allocator.free(@field(result, f.name));
                                    }
                                }
                                return error.MissingValue;
                            }
                            const value = args[arg_index + 1];
                            @field(result, field.name) = std.fmt.parseInt(field.type, value, 10) catch {
                                inline for (fields) |f| {
                                    if (@typeInfo(f.type) == .Pointer and f.type == []u8 and @field(result, f.name).len > 0) {
                                        allocator.free(@field(result, f.name));
                                    }
                                }
                                return error.InvalidIntValue; // New error for invalid int
                            };
                            arg_index += 1;
                        },
                        .Pointer => |ptr| if (ptr.child == u8) {
                            if (arg_index + 1 >= args.len) {
                                inline for (fields) |f| {
                                    if (@typeInfo(f.type) == .Pointer and f.type == []u8 and @field(result, f.name).len > 0) {
                                        allocator.free(@field(result, f.name));
                                    }
                                }
                                return error.MissingValue;
                            }
                            const value = args[arg_index + 1];
                            const copied = try allocator.dupe(u8, value);
                            @field(result, field.name) = copied;
                            arg_index += 1;
                        },
                        .Array => |arr| if (arr.child == u8) {
                            if (arg_index + 1 >= args.len) {
                                inline for (fields) |f| {
                                    if (@typeInfo(f.type) == .Pointer and f.type == []u8 and @field(result, f.name).len > 0) {
                                        allocator.free(@field(result, f.name));
                                    }
                                }
                                return error.MissingValue;
                            }
                            const value = args[arg_index + 1];
                            if (value.len > arr.len) {
                                inline for (fields) |f| {
                                    if (@typeInfo(f.type) == .Pointer and f.type == []u8 and @field(result, f.name).len > 0) {
                                        allocator.free(@field(result, f.name));
                                    }
                                }
                                return error.StringTooLong;
                            }
                            @memcpy(@field(result, field.name)[0..value.len], value);
                            arg_index += 1;
                        },
                        else => @compileError("Unsupported field type: " ++ @typeName(field.type)),
                    }
                }
            }
        }
    }

    return result;
}

pub fn deinit(comptime T: type, args: T, allocator: std.mem.Allocator) void {
    const fields = std.meta.fields(T);
    inline for (fields) |field| {
        if (@typeInfo(field.type) == .Pointer and field.type == []u8) {
            if (@field(args, field.name).len > 0) {
                allocator.free(@field(args, field.name));
            }
        }
    }
}
