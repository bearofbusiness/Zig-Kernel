const std = @import("std");

pub fn build(b: *std.Build) void {
    var disabled_features = std.Target.Cpu.Feature.Set.empty;
    var enabled_features = std.Target.Cpu.Feature.Set.empty;

    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.mmx));
    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.sse));
    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.sse2));
    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.avx));
    disabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.avx2));
    enabled_features.addFeature(@intFromEnum(std.Target.x86.Feature.soft_float));

    const target_query = std.Target.Query{
        .cpu_arch = std.Target.Cpu.Arch.x86,
        .os_tag = std.Target.Os.Tag.freestanding,
        .abi = std.Target.Abi.none,
        .cpu_features_sub = disabled_features,
        .cpu_features_add = enabled_features,
    };

    const optimize = b.standardOptimizeOption(.{});
    const target = b.resolveTargetQuery(target_query);

    const kernel = b.addExecutable(.{
        .name = "kernel.elf",
        .root_source_file = b.path("src/kernel/main.zig"),
        .target = target,
        .optimize = optimize,
        .code_model = .kernel,
    });

    kernel.addIncludePath(b.path("src"));

    // compile & link the hardware layer

    const ps2_io_obj = b.addObject(.{
        .name = "ps2_io",
        .root_source_file = b.path("src/hw/ps2_io.zig"),
        .target = target,
        .optimize = optimize,
    });

    kernel.addObject(ps2_io_obj);

    kernel.setLinkerScript(b.path("src/kernel/linker.ld"));
    b.installArtifact(kernel);

    //----------UNIT TESTS-----------//
    const test_step = b.step("test", "Run all tests");

    const keyboard_test = b.addTest(.{
        .root_source_file = b.path("src/tests/keyboard_test.zig"),
        .optimize = optimize,
    });

    const keyboard_mod = b.createModule(.{ .root_source_file = b.path("src/kernel/keyboard.zig") });

    keyboard_test.root_module.addImport("keyboard", keyboard_mod);

    test_step.dependOn(&keyboard_test.step);

    const kernel_step = b.step("kernel", "Build the kernel");
    kernel_step.dependOn(&kernel.step);
}
