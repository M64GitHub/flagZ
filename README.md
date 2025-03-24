# flagZ

![Tests](https://github.com/M64GitHub/flagZ/actions/workflows/test.yml/badge.svg)
![Version](https://img.shields.io/badge/version-1.1.0-blue?style=flat)
![License](https://img.shields.io/badge/license-MIT-brightgreen?style=flat)
![Zig](https://img.shields.io/badge/Zig-0.14.0-orange?style=flat)

Dead-simple flags to Zig structs—no fuss, flags: done!

## What It Does

Parses CLI flags into your Zig struct with fuzzy flag-name matching (e.g., `-name` or `-n` sets `name`). Supports strings (allocated), integers and floats (parsed), and booleans (set)—via `flagz.parse()` and `flagz.deinit()`. See Reference for supported types.

Optional fields (`?T`) are `null` if unset; others are initialized to 0, "", or `false` to ensure defined behavior.

## What It Does Not
No `--` flags, no fancy options, no bells or whistles. That’s on purpose—**flagZ** strips it down to dead-simple: your struct, your flags, done. Need more? Grab a full-featured lib—this is for quick, brain-dead-easy parsing, no headaches allowed!

## Why flagZ?

**flagZ** goal is to try to flip the script: define a struct, and boom your CLI interface and varieables are set, flags flow in, transparent as can be. No fuss.  
No learning curve, no docs to slog through. It’s not here to out-fancy the big libs—it’s your instant, transparent shortcut to flags without the fuss. **Focus on your code, not the setup**—**flagZ** has your back!

## Features
- Supports `bool`, all integers (`u1` to `u64`, `i1` to `i64`, `usize`, `isize`), floats (`f32`, `f64`), strings (`[]u8`, `[N]u8`), as well as their optional types.
- Short flags fuzzy match (`-v` flips `verbose`, `-n` fills `name`—first match wins!).
- Errors (`MissingValue`, `StringTooLong`, `InvalidIntValue`, `NegativeValueNotAllowed`, plus `Overflow` from `std`).

## Examples

### Parsing Non-Optional Fields

```zig
const std = @import("std");
const flagz = @import("flagz");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const Args = struct {
        name: []const u8,
        count: usize,
        offset: isize,
        limit: u32,
        shift: i32,
        temp: f32,
        rate: f64,
        verbose: bool,
        tag: [8]u8,
    };

    const args = try flagz.parse(Args, allocator);
    defer flagz.deinit(args, allocator);

    std.debug.print("Name: {s}\n", .{args.name});
    std.debug.print("Count (usize): {}\n", .{args.count});
    std.debug.print("Offset (isize): {}\n", .{args.offset});
    std.debug.print("Limit (u32): {}\n", .{args.limit});
    std.debug.print("Shift (i32): {}\n", .{args.shift});
    std.debug.print("Temp (f32): {}\n", .{args.temp});
    std.debug.print("Rate (f64): {}\n", .{args.rate});
    std.debug.print("Verbose: {}\n", .{args.verbose});
    std.debug.print("Tag: {s}\n", .{args.tag});
}
```

Run:
```bash
zig build run-nonopt -- -name "flagZ rockZ" -count 42 -offset -10 -limit 1000 -shift -500 -temp 23.5 -rate 0.001 -verbose -tag ziggy
```
Output:
```
Name: flagZ rockZ
Count (usize): 42
Offset (isize): -10
Limit (u32): 1000
Shift (i32): -500
Temp (f32): 2.35e1
Rate (f64): 1e-3
Verbose: true
Tag: ziggy
```

### Parsing Optional Fields

```zig
const std = @import("std");
const flagz = @import("flagz");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const Args = struct {
        count: ?usize, // null if unset
        verbose: bool, // false if unset
    };

    const args = try flagz.parse(Args, allocator);
    defer flagz.deinit(args, allocator);
    
    if (args.count) |c| std.debug.print("Count set: {}\n", .{c}) else std.debug.print("Count unset\n", .{});
    std.debug.print("Verbose: {}\n", .{args.verbose});
}
```
Runs and Outputs:
```bash
❯ zig build run-opt -- 
Count unset
Verbose: false

❯ zig build run-opt -- -v
Count unset
Verbose: true

❯ zig build run-opt -- -count 100
Count set: 100
Verbose: false
```

## Add flagZ To Your Project
```sh
zig fetch --save https://github.com/M64GitHub/flagZ/archive/refs/tags/v1.1.0.tar.gz
```
Adds the dependency to your `build.zig.zon`:
```zig
.dependencies = .{
    .flagz = .{
        .url = "https://github.com/M64GitHub/flagZ/archive/refs/tags/v1.1.0.tar.gz",
        .hash = "flagz-1.1.0-vdU1bKYQAQDVVb3UBuxamQwQ85AfhK-khpo075K2ympj",
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


## Reference: Supported Types

...

## License

**flagZ** is **MIT**—grab it, tweak it, twist it, share it, free as can be! Check [LICENSE](LICENSE) for the nitty-gritty.  

<br>

Developed with ❤️ by M64 - **flagZ-tastic** turbocharge your CLI game!


