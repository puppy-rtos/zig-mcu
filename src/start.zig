const std = @import("std");

pub const Handler = extern union {
    C: *const fn () callconv(.C) void,
    Naked: *const fn () callconv(.Naked) void,
    // Interrupt is not supported on arm
};

pub const unhandled = Handler{
    .C = struct {
        fn tmp() callconv(.C) noreturn {
            @panic("unhandled interrupt");
        }
    }.tmp,
};

pub const VectorTable = extern struct {
    initial_stack_pointer: u32,
    Reset: Handler = unhandled,
    NMI: Handler = unhandled,
    HardFault: Handler = unhandled,
    MemManageFault: Handler = unhandled,
    BusFault: Handler = unhandled,
    UsageFault: Handler = unhandled,
    reserved5: [4]u32 = undefined,
    SVCall: Handler = unhandled,
    reserved10: [2]u32 = undefined,
    PendSV: Handler = unhandled,
    SysTick: Handler = unhandled,
};

pub const vector_table: VectorTable = blk: {
    const tmp: VectorTable = .{
        .initial_stack_pointer = 0x20001000,
        .Reset = .{ .C = startup_logic._start },
    };

    break :blk tmp;
};

pub const startup_logic = struct {

    // it looks odd to just use a u8 here, but in C it's common to use a
    // char when linking these values from the linkerscript. What's
    // important is the addresses of these values.
    extern var microzig_data_start: u8;
    extern var microzig_data_end: u8;
    extern var microzig_bss_start: u8;
    extern var microzig_bss_end: u8;
    extern var microzig_stack_end: u8;
    extern const microzig_data_load_start: u8;

    pub fn _start() callconv(.C) noreturn {

        // set sp to the end of the stack
        asm volatile ("ldr sp, =microzig_stack_end");

        // fill .bss with zeroes
        {
            const bss_start: [*]u8 = @ptrCast(&microzig_bss_start);
            const bss_end: [*]u8 = @ptrCast(&microzig_bss_end);
            const bss_len = @intFromPtr(bss_end) - @intFromPtr(bss_start);

            @memset(bss_start[0..bss_len], 0);
        }

        // load .data from flash
        {
            const data_start: [*]u8 = @ptrCast(&microzig_data_start);
            const data_end: [*]u8 = @ptrCast(&microzig_data_end);
            const data_len = @intFromPtr(data_end) - @intFromPtr(data_start);
            const data_src: [*]const u8 = @ptrCast(&microzig_data_load_start);

            @memcpy(data_start[0..data_len], data_src[0..data_len]);
        }

        microzig_main();
    }
};

pub fn export_startup_logic() void {
    @export(startup_logic._start, .{
        .name = "_start",
    });
}

// Startup logic:
comptime {
    // Instantiate the startup logic for the given CPU type.
    // This usually implements the `_start` symbol that will populate
    // the sections .data and .bss with the correct data.
    // .rodata is not always necessary to be populated (flash based systems
    // can just index flash, while harvard or flash-less architectures need
    // to copy .rodata into RAM).
    export_startup_logic();

    // Export the vector table to flash start if we have any.
    // For a lot of systems, the vector table provides a reset vector
    // that is either called (Cortex-M) or executed (AVR) when initalized.

    // Allow board and chip to override CPU vector table.
    const export_opts = .{
        .name = "vector_table",
        .section = "microzig_flash_start",
        .linkage = .strong,
    };

    @export(vector_table, export_opts);
}

/// This is the logical entry point for microzig.
/// It will invoke the main function from the root source file
/// and provides error return handling as well as a event loop if requested.
///
/// Why is this function exported?
/// This is due to the modular design of microzig to allow the "chip" dependency of microzig
/// to call into our main function here. If we would use a normal function call, we'd have a
/// circular dependency between the `microzig` and `chip` package. This function is also likely
/// to be invoked from assembly, so it's also convenient in that regard.
export fn microzig_main() noreturn {
    const main_fn = @import("main.zig").main;
    main_fn();
}
