# flagZ

Dead-simple flags to Zig structs—no fuss, flags: done!

## What It Does
Parses CLI flags into your Zig struct—flag names match field names (e.g., `-name` fills `name`). Strings (`[]u8`) are allocated, integers (`usize`) parsed, booleans flipped—call `flagz.parse()` to fill it, `flagz.deinit()` to clean up. Supports any fields you define!

## What It Does Not
No `--` flags, no fancy options, no bells or whistles. That’s on purpose—**flagZ** strips it down to dead-simple: your struct, your flags, done. Need more? Grab a full-featured lib—this is for quick, brain-dead-easy parsing, no headaches allowed!

## Why flagZ?

Because CLI args shouldn’t suck. Loops, conditionals, type chaos? Nope! **flagZ** flips the script: define a struct, and boom your CLI interface is set, flags flow in, transparent as can be. No fuss.  

Ever hacked a tool and thought, “Ugh, CLI flags—how’d that work again?” Digging through old projects, copy-pasting, tweaking—such a drag! **flagZ** was born to zap that hassle: define a struct, and bam—it’s your CLI **and** your variables, no learning curve, no docs to slog through. It’s not here to out-fancy the big libs—it’s your instant, transparent shortcut to flags without the fuss. **Focus on your code, not the setup**—**flagZ** has your back!




## Example

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



## Add flagZ To Your Project
```sh
zig fetch --save https://github.com/M64GitHub/flagZ/archive/refs/tags/v0.0.2-alpha.tar.gz
```
Adds the dependency to your `build.zig.zon`:
```zig
.dependencies = .{
    .flagz = .{
        .url = "https://github.com/M64GitHub/flagZ/archive/refs/tags/v0.1.0-alpha.tar.gz",
        .hash = "flagz-0.1.0-vdU1bJ9KAAAFSkBuPA54O65FBsuk8SAwzIhYiZp5Ron-",
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
