const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    Ensure_Minimal_Zig_Version() catch
        @panic("Zig 0.14.0 or higher is required for compilation!");

    const name = "sorts-visualized";
    const src_filepath = "src/";
    const main_filepath = src_filepath ++ "main.zig";
    const tests_filepath = src_filepath ++ "tests.zig";

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // raylib module dependencies
    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
        .shared = true,
    });
    const raylib_mod = raylib_dep.module("raylib");
    const raygui_mod = raylib_dep.module("raygui");
    const raylib_core = raylib_dep.artifact("raylib");

    const exe = b.addExecutable(.{
        .name = name,
        .root_module = b.createModule(.{
            .root_source_file = b.path(main_filepath),
            .target = target,
            .optimize = optimize,
        }),
    });
    exe.linkLibrary(raylib_core);
    exe.root_module.addImport("raylib", raylib_mod);
    exe.root_module.addImport("raygui", raygui_mod);
    b.installArtifact(exe);

    // format source files
    const format_options = std.Build.Step.Fmt.Options{ .paths = &.{src_filepath} };
    const performStep_format = b.addFmt(format_options);
    b.default_step.dependOn(&performStep_format.step);

    // unit testing
    const added_tests = b.addTest(.{ .root_source_file = b.path(tests_filepath) });
    added_tests.linkLibrary(raylib_core);
    added_tests.root_module.addImport("raylib", raylib_mod);
    added_tests.root_module.addImport("raygui", raygui_mod);
    const performStep_test = b.addRunArtifact(added_tests);
    b.default_step.dependOn(&performStep_test.step);

    // run executable
    var run_step = b.step("run", "Run the executable");
    const performStep_run = b.addRunArtifact(exe);
    if (b.args) |args|
        performStep_run.addArgs(args);
    run_step.dependOn(&performStep_run.step);
}

/// Assert Zig 0.14.0 or higher
pub fn Ensure_Minimal_Zig_Version() !void {
    const current_version = builtin.zig_version;
    const minimum_version = std.SemanticVersion{
        .major = 0,
        .minor = 14,
        .patch = 0,
        .build = null,
        .pre = null,
    };
    switch (std.SemanticVersion.order(current_version, minimum_version)) {
        .lt => return error.OutdatedVersion,
        .eq => {},
        .gt => {},
    }
}
