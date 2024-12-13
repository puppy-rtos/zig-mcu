const std = @import("std");

pub fn add(a: u8, b: u8) u8 {
    return a + b;
}

export fn main() void {
    const c = add(10, 11);

    _ = c;
    while (true) {}
}

export fn subcpu_entry() void {
    while (true) {}
}
