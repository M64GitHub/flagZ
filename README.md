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
    defer flagz.deinit(Args, args, allocator);

    std.debug.print("Name: {s}\n", .{args.name});
    std.debug.print("Count: {}\n", .{args.count});
    std.debug.print("Verbose: {}\n", .{args.verbose});
    std.debug.print("Tag: {s}\n", .{args.tag});
}
```

Run: `./example -name hello -count 42 -verbose -tag ziggy`

<br>

## flagZ Your Project
```sh
zig fetch --save https://github.com/M64GitHub/flagZ/archive/refs/tags/v0.0.2-alpha.tar.gz
```
Adds the dependency to your `build.zig.zon`:
```zig
.dependencies = .{
    .flagz = .{
        .url = "https://github.com/M64GitHub/flagZ/archive/refs/tags/v0.0.2-alpha.tar.gz",
        .hash = "122017824624d89917d0e281c85a32c5151900af33621638b4c7c3b355b11cb81cff",
    },
},
```

`build.zig`: import `flagZ` as follows:
```zig
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Add flagZ
    const dep_flagz = b.dependency("flagz", .{}); 
    const mod_flagz = dep_flagz.module("flagz");  

    // Your executable
    const exe = b.addExecutable(.{
        .name = "e-x-e",
        .root_source_file = b.path("src/exe.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Link flagZ
    exe.root_module.addImport("flagz", mod_flagz); 

    b.installArtifact(exe);
}
```
