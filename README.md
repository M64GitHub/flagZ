# flagZ

Dead-simple flags to Zig structs—no fuss, flags: done!

## What It Does

Define a struct. Pass it to `flagz.parse()`. Your CLI flags fill it automagically. No docs to slog through, no complex setup—just your work, done.

## Why flagZ?

Because CLI args shouldn’t suck. Define your struct, and let the flags revolution begin!

## Example

```zig
const std = @import(\"std\");
const flagz = @import(\"flagz.zig\");

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
    defer allocator.free(args.name);

    std.debug.print(\"Name: {s}\
\", .{args.name});
    std.debug.print(\"Count: {}\
\", .{args.count});
    std.debug.print(\"Verbose: {} (flags revolution begins!)\
\", .{args.verbose});
    std.debug.print(\"Tag: {s}\
\", .{args.tag});
}
```

Run:  
```bash
zig build run -- -name hello -count 42 -verbose -tag ziggy
```
```bash
./example -name hello -count 42 -verbose -tag ziggy
```

## Install

Clone this repo and add `flagz.zig` to your project. More soon!

