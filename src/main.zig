const std = @import("std");
const gpio = @import("stm32f4/gpio.zig");

export fn main() void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    const led = gpio.Gpio("PC13") catch return;

    led.mode(gpio.Gpio_Mode.Output);
    led.write(gpio.Gpio_Level.Low);
    while (true) {}
}

export fn subcpu_entry() void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    while (true) {}
}
