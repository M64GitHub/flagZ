# flagZ

Dead-simple flags to Zig structs—no fuss, flags: done!

## What It Does

Define a struct. Pass it to `flagz.parse()`. Your CLI flags fill it automagically. No docs to slog through, no complex setup—just your work, done.

## Why flagZ?

Because CLI args shouldn’t suck. Define your struct, and let the flags revolution begin!

Flag parsing in command-line tools can be a chore—loops, conditionals, type conversions, ugh! Enter **flagZ**, a Zig module that turns this mess into a one-liner: define a struct, call `flagz.parse()`, and boom—your flags are in, no fuss. 

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
    defer flagz.deinit(Args, args, allocator);

    std.debug.print("Name: {s}\n", .{args.name});
    std.debug.print("Count: {}\n", .{args.count});
    std.debug.print("Verbose: {}\n", .{args.verbose});
    std.debug.print("Tag: {s}\n", .{args.tag});
}
```

Run: `./example -name hello -count 42 -verbose -tag ziggy`

## Install

Clone this repo and add `flagz.zig` to your project. More soon!

