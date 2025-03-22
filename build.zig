const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // flagz module
    const flagz_module = b.addModule("flagz", .{
        .root_source_file = b.path("src/flagz.zig"),
    });

    // example executable
    const exe = b.addExecutable(.{
        .name = "example",
        .root_source_file = b.path("src/example.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("flagz", flagz_module);
    b.installArtifact(exe);

    // Run the example
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the example");
    run_step.dependOn(&run_cmd.step);

    // Tests
    const tests = b.addTest(.{ .root_source_file = b.path("src/test.zig") });
    tests.root_module.addImport("flagz", flagz_module);
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_tests.step);
}
