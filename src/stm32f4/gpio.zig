const std = @import("std");
const GPIO_Type = @import("regs.zig").types.peripherals.GPIOA;
const RCC_Type = @import("regs.zig").types.peripherals.RCC;

pub const Gpio_Mode = enum { Input, Output };
pub const Gpio_Level = enum { Low, High };

pub fn Gpio(name: []const u8) !GpioType {
    return init(name);
}

const GpioType = struct {
    data: GpioData,
    // ops for pin
    ops: *const GpioOps,
    // set pin mode
    pub fn mode(self: *const @This(), pin_mode: Gpio_Mode) void {
        self.ops.mode(self, pin_mode);
    }
    // write pin
    pub fn write(self: *const @This(), value: Gpio_Level) void {
        self.ops.write(self, value);
    }
    // read pin
    pub fn read(self: *const @This()) Gpio_Level {
        return self.ops.read(self);
    }
};

const GpioData = struct {
    port: *volatile GPIO_Type,
    pin: u8,
};

const GpioOps = struct {
    // init the flash
    mode: *const fn (self: *const GpioType, pin_mode: Gpio_Mode) void,
    // write the flash
    write: *const fn (self: *const GpioType, value: Gpio_Level) void,
    // read the flash
    read: *const fn (self: *const GpioType) Gpio_Level,
};

// pin set mode
fn set_mode(self: *const GpioType, pin_mode: Gpio_Mode) void {
    const port: *volatile GPIO_Type = self.data.port;
    const pin: u8 = self.data.pin;
    if (pin_mode == Gpio_Mode.Output) {
        var moder_raw: u32 = port.MODER.raw;
        moder_raw = moder_raw & ~std.math.shl(u32, 0b11, pin * 2);
        moder_raw = moder_raw | std.math.shl(u32, 0b01, pin * 2);
        port.MODER.raw = moder_raw;
    } else if (pin_mode == Gpio_Mode.Input) {
        var moder_raw: u32 = port.MODER.raw;
        moder_raw = moder_raw & ~std.math.shl(u32, 0b11, pin * 2);
        port.MODER.raw = moder_raw;
    }
}

// pin write
fn write(self: *const GpioType, value: Gpio_Level) void {
    const port: *volatile GPIO_Type = self.data.port;
    const pin: u8 = self.data.pin;
    if (value == Gpio_Level.High) {
        port.ODR.raw = port.ODR.raw | std.math.shl(u32, 1, pin);
    } else {
        port.ODR.raw = port.ODR.raw & ~std.math.shl(u32, 1, pin);
    }
}

// pin read
fn read(self: *const GpioType) Gpio_Level {
    const port: *volatile GPIO_Type = self.data.port;
    const pin: u8 = self.data.pin;
    const idr_raw = port.IDR.raw;
    const pin_set = std.math.shl(u32, 1, pin);
    if (idr_raw & pin_set != 0) {
        return Gpio_Level.High;
    } else {
        return Gpio_Level.Low;
    }
}

const ops: GpioOps = .{
    .mode = &set_mode,
    .write = &write,
    .read = &read,
};

fn init(name: []const u8) !GpioType {
    // parse name
    const port_num = name[1] - 'A';
    const port_addr: u32 = 0x40020000 + 0x400 * @as(u32, port_num);
    const pin_num: u32 = try parseU32(name[2..]);

    var self: GpioType = .{ .data = .{ .port = @as(*volatile GPIO_Type, @ptrFromInt(port_addr)), .pin = @intCast(pin_num) }, .ops = &ops };

    // Enable GPIOX(A..) port
    const RCC = @as(*volatile RCC_Type, @ptrFromInt(0x40023800));
    var ahb1enr_raw = RCC.AHB1ENR.raw;
    ahb1enr_raw = ahb1enr_raw | std.math.shl(u32, 1, port_num);
    RCC.AHB1ENR.raw = ahb1enr_raw;
    // Enable GpioX to output
    var moder_raw: u32 = self.data.port.MODER.raw;
    // todo: optimize
    moder_raw = moder_raw & ~std.math.shl(u32, 0b11, self.data.pin * 2);
    moder_raw = moder_raw | std.math.shl(u32, 0b01, self.data.pin * 2);
    self.data.port.MODER.raw = moder_raw;

    return self;
}

fn parseU32(input: []const u8) !u32 {
    var tmp: u32 = 0;
    for (input) |c| {
        if (c == 0) {
            break;
        }
        const digit = try std.fmt.charToDigit(c, 10);
        tmp = tmp * 10 + @as(u32, digit);
    }
    return tmp;
}
