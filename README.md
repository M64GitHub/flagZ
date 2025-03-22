# flagZ

Dead-simple flags to Zig structs—no fuss, flags: done!

## What It Does
Parses CLI flags into your Zig struct—flag names match field names (e.g., `-name` fills `name`). Strings (`[]u8`) are allocated, integers (`usize`) parsed, booleans flipped—call `flagz.parse()` to fill it, `flagz.deinit()` to clean up. Supports any fields you define!

## Why flagZ?

Because CLI args shouldn’t suck. Endless loops, conditionals, type juggling—nope! **flagZ** flips the script: define a struct, and *that’s it*—your CLI interface is set, flags flow in, transparent as can be. No fuss.

## Example

```zig
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
    defer flagz.deinit(args, allocator);

    std.debug.print("Name: {s}\n", .{args.name});
    std.debug.print("Count: {}\n", .{args.count});
    std.debug.print("Verbose: {}\n", .{args.verbose});
    std.debug.print("Tag: {s}\n", .{args.tag});
}
```

Run: `./example -name hello -count 42 -verbose -tag ziggy`

## Install

Clone this repo and add `flagz.zig` to your project. More soon!

