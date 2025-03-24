# flagZ

![Tests](https://github.com/M64GitHub/flagZ/actions/workflows/test.yml/badge.svg)
![License](https://img.shields.io/badge/license-MIT-brightgreen?style=flat)
![Version](https://img.shields.io/badge/version-1.0.0-8a2be2?style=flat)
![Zig](https://img.shields.io/badge/Zig-0.14.0-orange?style=flat)

Field names define `-flags` in Zig structs—direct parsing, concise, clear-cut. Aiming to keep it simple.

## What It Does

Parses CLI flags into your Zig struct with fuzzy flag-name matching (e.g., `-name` or `-n` sets `name`). Supports strings (allocated), integers and floats (parsed), and booleans (set)—via `flagz.parse()` and `flagz.deinit()`.  
See Reference for supported types.

Optional fields (`?T`) are `null` if unset; others are initialized to `0`, `""`, or `false` to ensure defined behavior.

## What It Does Not

**flagZ** omits double-dash `--` flags, advanced options, and extra features by design. It focuses solely on straightforward struct-based flag parsing. For complex needs, use a comprehensive library—**flagZ** prioritizes simplicity and efficiency over extensive functionality.

## Features
- Supports `bool`, integers (`u1` to `u8388608`, `i1` to `i8388608`, including `usize`, `isize`), floats (`f32`, `f64`), and strings (`[]u8`, `[N]u8`), with optional variants (`?T`).
- Short flags use fuzzy matching (e.g., `-v` sets `verbose`, `-n` sets `name`—first match wins).
- Errors include `MissingValue`, `StringTooLong`, `InvalidIntValue`, `NegativeValueNotAllowed`, and `Overflow` (from `std`).

## Why flagZ?

Command-line tools in Zig often require parameters, yet managing them can lead to complexity—ad-hoc fixes, library hunts, and repetitive code across projects. **flagZ** seeks to streamline this for Zig developers. With Zig’s comptime capabilities, its core strength is simple: field names directly define argument names—a transparent, efficient shortcut, not a rival to full-featured libraries.


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

flagZ supports the following types for flag parsing, with explicit initialization to ensure predictable behavior—avoiding undefined values for reliability. Numeric types parse in base 10.

### Booleans
- **`bool`**—Sets to `true` only if the flag is present on the command line, otherwise `false`.
- **`?bool`**—Sets to `true` if the flag is present, `null` if unset.

### Integers (Unsigned)
- **`uN`** (e.g., `u1`, `u8`, `u32`, `u8388608`, `usize`)—Parses to the specified unsigned integer type, initialized to 0 if unset.
- **`?uN`**—Parses to the specified unsigned integer type, `null` if unset.

### Integers (Signed)
- **`iN`** (e.g., `i1`, `i32`, `i8388608`, `isize`)—Parses to the specified signed integer type, initialized to 0 if unset.
- **`?iN`**—Parses to the specified signed integer type, `null` if unset.

### Floats
- **`f32`, `f64`**—Parses to the specified floating-point type, initialized to 0.0 if unset.
- **`?f32`, `?f64`**—Parses to the specified floating-point type, `null` if unset.

### Strings
- **`[]u8`**—Allocates the flag value as a string, initialized to "" if unset.
- **`?[]u8`**—Allocates the flag value as a string, `null` if unset.
- **`[N]u8`**—Copies the flag value into a fixed-size array, initialized to all zeros if unset.

*Note*: Optional fixed-size arrays (e.g., `?[N]u8`) are not supported due to Zig’s type system, which does not allow nullability for arrays with fixed lengths.

## License

**flagZ** is **MIT**—grab it, tweak it, twist it, share it, free as can be! Check [LICENSE](LICENSE) for the nitty-gritty.  

<br>

Developed with ❤️ by M64 - **flagZ-tastic** turbocharge your CLI game!


