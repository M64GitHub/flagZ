# flagZ

![Tests](https://github.com/M64GitHub/flagZ/actions/workflows/test.yml/badge.svg)
![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat)
![License](https://img.shields.io/badge/license-MIT-brightgreen?style=flat)
![Zig](https://img.shields.io/badge/Zig-0.14.0-orange?style=flat)

Dead-simple flags to Zig structs—no fuss, flags: done!

## What It Does
Parses CLI flags into your Zig struct—flag names fuzzy match field names (e.g., `-name` or `-n` fills `name`). Strings (`[]u8`) are allocated, integers (`usize`, `isize`) parsed, floats (`f32`, `f64`) zapped, booleans flipped—call `flagz.parse()` to fill it, `flagz.deinit()` to clean up. See below for all supported types.  

Optional fields (`?T`) stay `null` if unset, others get defaults (`0`, `""`, `false`)! Supports any fields you define!

## What It Does Not
No `--` flags, no fancy options, no bells or whistles. That’s on purpose—**flagZ** strips it down to dead-simple: your struct, your flags, done. Need more? Grab a full-featured lib—this is for quick, brain-dead-easy parsing, no headaches allowed!

## Why flagZ?

Because CLI args shouldn’t suck. Loops, conditionals, type chaos? Nope! **flagZ** flips the script: define a struct, and boom your CLI interface is set, flags flow in, transparent as can be. No fuss.  

Ever hacked a tool and thought, “Ugh, CLI flags—how’d that work again?” Digging through old projects, copy-pasting, tweaking—such a drag! **flagZ** was born to zap that hassle: define a struct, and bam—it’s your CLI **and** your variables, no learning curve, no docs to slog through. It’s not here to out-fancy the big libs—it’s your instant, transparent shortcut to flags without the fuss. **Focus on your code, not the setup**—**flagZ** has your back!

## Features
- Supports `bool`, all integers (`u1` to `u64`, `i1` to `i64`, `usize`, `isize`), floats (`f32`, `f64`), strings (`[]u8`, `[N]u8`), as well as their optional types.
- Short flags fuzzy zap (`-v` flips `verbose`, `-n` fills `name`—first match wins!).
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

## flagZ vs. The World

**flagZ** nails 48 tests—smooth flags, tricky cases, overflows, weird, all crushed! From `usize` to `f64`, it’s tight and leak-free. Flags drop, flawless pop!


## Add flagZ To Your Project
```sh
zig fetch --save https://github.com/M64GitHub/flagZ/archive/refs/tags/v1.1.0.tar.gz
```
Adds the dependency to your `build.zig.zon`:
```zig
.dependencies = .{
    .flagz = .{
        .url = "https://github.com/M64GitHub/flagZ/archive/refs/tags/v1.1.0.tar.gz",
        .hash = "flagz-1.1.0-",
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

### Booleans
- **`bool`**—Flips to `true` with flag (e.g., `-verbose`), defaults to `false` if unset.
- **`?bool`**—Sets to `true` with flag, `null` if unset.

### Integers (Unsigned)
- **`usize`**—Parsed with `parseInt(i64)`, defaults to `0` if unset.
- **`u1`**—Parsed with `parseInt(i64)`, defaults to `0` if unset (0-1 range).
- **`u2`**—Parsed with `parseInt(i64)`, defaults to `0` if unset (0-3 range).
- **`u4`**—Parsed with `parseInt(i64)`, defaults to `0` if unset (0-15 range).
- **`u8`**—Parsed with `parseInt(i64)`, defaults to `0` if unset (0-255 range).
- **`u16`**—Parsed with `parseInt(i64)`, defaults to `0` if unset (0-65535 range).
- **`u32`**—Parsed with `parseInt(i64)`, defaults to `0` if unset (0-4294967295 range).
- **`u64`**—Parsed with `parseInt(i64)`, defaults to `0` if unset (0-2^64-1 range).
- **`?usize`**—Parsed with `parseInt(i64)`, `null` if unset, else value.
- **`?u1`**—Parsed with `parseInt(i64)`, `null` if unset, else 0-1.
- **`?u2`**—Parsed with `parseInt(i64)`, `null` if unset, else 0-3.
- **`?u4`**—Parsed with `parseInt(i64)`, `null` if unset, else 0-15.
- **`?u8`**—Parsed with `parseInt(i64)`, `null` if unset, else 0-255.
- **`?u16`**—Parsed with `parseInt(i64)`, `null` if unset, else 0-65535.
- **`?u32`**—Parsed with `parseInt(i64)`, `null` if unset, else 0-4294967295.
- **`?u64`**—Parsed with `parseInt(i64)`, `null` if unset, else 0-2^64-1.

### Integers (Signed)
- **`isize`**—Parsed with `parseInt(i64)`, defaults to `0` if unset.
- **`i1`**—Parsed with `parseInt(i64)`, defaults to `0` if unset (-1 to 0 range).
- **`i2`**—Parsed with `parseInt(i64)`, defaults to `0` if unset (-2 to 1 range).
- **`i4`**—Parsed with `parseInt(i64)`, defaults to `0` if unset (-8 to 7 range).
- **`i8`**—Parsed with `parseInt(i64)`, defaults to `0` if unset (-128 to 127 range).
- **`i16`**—Parsed with `parseInt(i64)`, defaults to `0` if unset (-32768 to 32767 range).
- **`i32`**—Parsed with `parseInt(i64)`, defaults to `0` if unset (-2147483648 to 2147483647 range).
- **`i64`**—Parsed with `parseInt(i64)`, defaults to `0` if unset (-2^63 to 2^63-1 range).
- **`?isize`**—Parsed with `parseInt(i64)`, `null` if unset, else value.
- **`?i1`**—Parsed with `parseInt(i64)`, `null` if unset, else -1 to 0.
- **`?i2`**—Parsed with `parseInt(i64)`, `null` if unset, else -2 to 1.
- **`?i4`**—Parsed with `parseInt(i64)`, `null` if unset, else -8 to 7.
- **`?i8`**—Parsed with `parseInt(i64)`, `null` if unset, else -128 to 127.
- **`?i16`**—Parsed with `parseInt(i64)`, `null` if unset, else -32768 to 32767.
- **`?i32`**—Parsed with `parseInt(i64)`, `null` if unset, else -2147483648 to 2147483647.
- **`?i64`**—Parsed with `parseInt(i64)`, `null` if unset, else -2^63 to 2^63-1.

### Floats
- **`f32`**—Parsed with `parseFloat`, defaults to `0.0` if unset.
- **`f64`**—Parsed with `parseFloat`, defaults to `0.0` if unset.
- **`?f32`**—Parsed with `parseFloat`, `null` if unset, else value.
- **`?f64`**—Parsed with `parseFloat`, `null` if unset, else value.

### Strings
- **`[]u8`**—Allocated with `dupe`, defaults to `""` if unset.
- **`?[]u8`**—Allocated with `dupe`, `null` if unset, else value.
- **`[N]u8`** (e.g., `[8]u8`)—Copied with `memcpy`, defaults to all zeros if unset (e.g., `[0]u8{0...}`).


## License

**flagZ** is **MIT**—grab it, tweak it, twist it, share it, free as can be! Check [LICENSE](LICENSE) for the nitty-gritty.  

<br>

Developed with ❤️ by M64 - **flagZ-tastic** turbocharge your CLI game!


