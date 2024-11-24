const std = @import("std");

const stm32f4 = std.zig.CrossTarget{
    .cpu_arch = .thumb,
    .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m4 },
    .os_tag = .freestanding,
    .abi = .eabihf,
};

const riscv32 = std.zig.CrossTarget{
    .cpu_arch = .riscv32,
    .os_tag = .freestanding,
    .abi = .none,
};

const available_boards = [_]Board{
    .{ .name = "riscv32", .target = riscv32, .start_file = "src/riscv32/start.s", .linker_script = "src/riscv32/link.lds" },
    .{ .name = "stm32f4", .target = stm32f4, .start_file = "src/stm32f4/start.s", .linker_script = "src/stm32f4/link.lds" },
};

pub fn build(b: *std.Build) void {
    const optimize = .ReleaseSmall;

    for (available_boards) |board| {
        const elf = b.addExecutable(.{
            .name = b.fmt("{s}{s}", .{ board.name, ".elf" }),
            .root_source_file = b.path("src/main.zig"),
            .target = b.resolveTargetQuery(board.target),
            .optimize = optimize,
            .strip = false, // do not strip debug symbols
        });

        elf.setLinkerScript(b.path(board.linker_script));
        elf.addCSourceFile(.{ .file = b.path(board.start_file), .flags = &.{} });

        // Copy the elf to the output directory.
        const copy_elf = b.addInstallArtifact(elf, .{});
        b.default_step.dependOn(&copy_elf.step);

        // Convert the hex from the elf
        const hex = b.addObjCopy(elf.getEmittedBin(), .{ .format = .hex });
        hex.step.dependOn(&elf.step);
        // Copy the hex to the output directory
        const copy_hex = b.addInstallBinFile(
            hex.getOutput(),
            b.fmt("{s}{s}", .{ board.name, ".hex" }),
        );
        b.default_step.dependOn(&copy_hex.step);

        // Convert the bin form the elf
        const bin = b.addObjCopy(elf.getEmittedBin(), .{ .format = .bin });
        bin.step.dependOn(&elf.step);

        // Copy the bin to the output directory
        const copy_bin = b.addInstallBinFile(
            bin.getOutput(),
            b.fmt("{s}{s}", .{ board.name, ".bin" }),
        );
        b.default_step.dependOn(&copy_bin.step);
    }
}

const Board = struct {
    target: std.zig.CrossTarget,
    name: []const u8,
    start_file: []const u8,
    linker_script: []const u8,
};
