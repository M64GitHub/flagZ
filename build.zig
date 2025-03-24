const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // -- flagz module
    const flagz_module = b.addModule("flagz", .{
        .root_source_file = b.path("src/flagz.zig"),
    });

    // -- Example executable non optional fields
    const exe_nonopt = b.addExecutable(.{
        .name = "example-nonopt",
        .root_source_file = b.path("src/example-nonopt.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_nonopt.root_module.addImport("flagz", flagz_module);
    b.installArtifact(exe_nonopt);

    // Run the non-opt example
    const run_cmd_nonopt = b.addRunArtifact(exe_nonopt);
    run_cmd_nonopt.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd_nonopt.addArgs(args);
    }

    const run_step_nonopt = b.step("run-nonopt", "Run the example");
    run_step_nonopt.dependOn(&run_cmd_nonopt.step);

    // -- Example executable optional fields
    const exe_opt = b.addExecutable(.{
        .name = "example-opt",
        .root_source_file = b.path("src/example-opt.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_opt.root_module.addImport("flagz", flagz_module);
    b.installArtifact(exe_opt);

    // Run the non-opt example
    const run_cmd_opt = b.addRunArtifact(exe_opt);
    run_cmd_opt.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd_opt.addArgs(args);
    }

    const run_step_opt = b.step("run-opt", "Run the example");
    run_step_opt.dependOn(&run_cmd_opt.step);

    // -- Tests
    const tests = b.addTest(.{
        .root_source_file = b.path("src/test.zig"),
    });
    tests.root_module.addImport("flagz", flagz_module);
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_tests.step);
}
