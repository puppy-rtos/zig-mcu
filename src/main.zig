const std = @import("std");
const gpio = @import("stm32f4/gpio.zig");
const clock = @import("stm32f4/clock.zig");

export fn main() noreturn {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    const led = gpio.Gpio("PC13") catch unreachable;
    clock.clock_init();

    led.mode(gpio.Gpio_Mode.Output);
    while (true) {
        led.write(gpio.Gpio_Level.Low);
        clock.delay_ms(1000);

        led.write(gpio.Gpio_Level.High);
        clock.delay_ms(1000);
    }
}

export fn subcpu_entry() noreturn {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    while (true) {}
}
