const std = @import("std");

pub fn add(a: u8, b: u8) u8 {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    return a + b;
}

export fn main() void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    const c = add(10, 11);

    _ = c;
    while (true) {}
}

export fn subcpu_entry() void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    while (true) {}
}
