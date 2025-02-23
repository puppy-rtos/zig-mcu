const std = @import("std");

const devicetree = @import("devicetree_f4.zig");

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
        var moder_raw: u32 = port.MODER;
        moder_raw = moder_raw & ~std.math.shl(u32, 0b11, pin * 2);
        moder_raw = moder_raw | std.math.shl(u32, 0b01, pin * 2);
        port.MODER = moder_raw;
    } else if (pin_mode == Gpio_Mode.Input) {
        var moder_raw: u32 = port.MODER;
        moder_raw = moder_raw & ~std.math.shl(u32, 0b11, pin * 2);
        port.MODER = moder_raw;
    }
}

// pin write
fn write(self: *const GpioType, value: Gpio_Level) void {
    const port: *volatile GPIO_Type = self.data.port;
    const pin: u8 = self.data.pin;
    if (value == Gpio_Level.High) {
        port.ODR = port.ODR | std.math.shl(u32, 1, pin);
    } else {
        port.ODR = port.ODR & ~std.math.shl(u32, 1, pin);
    }
}

// pin read
fn read(self: *const GpioType) Gpio_Level {
    const port: *volatile GPIO_Type = self.data.port;
    const pin: u8 = self.data.pin;
    const idr_raw = port.IDR;
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
    const port_addr: u32 = devicetree.gpio_addr + 0x400 * @as(u32, port_num);
    const pin_num: u32 = try parseU32(name[2..]);

    var self: GpioType = .{ .data = .{ .port = @as(*volatile GPIO_Type, @ptrFromInt(port_addr)), .pin = @intCast(pin_num) }, .ops = &ops };

    // Enable GPIOX(A..) port
    const RCC = @as(*volatile RCC_Type, @ptrFromInt(devicetree.rcc_addr));
    var ahb1enr_raw = RCC.AHB1ENR;
    ahb1enr_raw = ahb1enr_raw | std.math.shl(u32, 1, port_num);
    RCC.AHB1ENR = ahb1enr_raw;
    // Enable GpioX to output
    var moder_raw: u32 = self.data.port.MODER;
    // todo: optimize
    moder_raw = moder_raw & ~std.math.shl(u32, 0b11, self.data.pin * 2);
    moder_raw = moder_raw | std.math.shl(u32, 0b01, self.data.pin * 2);
    self.data.port.MODER = moder_raw;

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
///  General-purpose I/Os
const GPIO_Type = extern struct {
    ///  GPIO port mode register
    MODER: u32,
    ///  GPIO port output type register
    OTYPER: u32,
    ///  GPIO port output speed register
    OSPEEDR: u32,
    ///  GPIO port pull-up/pull-down register
    PUPDR: u32,
    ///  GPIO port input data register
    IDR: u32,
    ///  GPIO port output data register
    ODR: u32,
    ///  GPIO port bit set/reset register
    BSRR: u32,
    ///  GPIO port configuration lock register
    LCKR: u32,
    ///  GPIO alternate function low register
    AFRL: u32,
    ///  GPIO alternate function high register
    AFRH: u32,
};

const RCC_Type = extern struct {
    ///  clock control register
    CR: u32,
    ///  PLL configuration register
    PLLCFGR: u32,
    ///  clock configuration register
    CFGR: u32,
    ///  clock interrupt register
    CIR: u32,
    ///  AHB1 peripheral reset register
    AHB1RSTR: u32,
    ///  AHB2 peripheral reset register
    AHB2RSTR: u32,
    ///  AHB3 peripheral reset register
    AHB3RSTR: u32,
    reserved32: [4]u8,
    ///  APB1 peripheral reset register
    APB1RSTR: u32,
    ///  APB2 peripheral reset register
    APB2RSTR: u32,
    reserved48: [8]u8,
    ///  AHB1 peripheral clock register
    AHB1ENR: u32,
    ///  AHB2 peripheral clock enable register
    AHB2ENR: u32,
    ///  AHB3 peripheral clock enable register
    AHB3ENR: u32,
    reserved64: [4]u8,
    ///  APB1 peripheral clock enable register
    APB1ENR: u32,
    ///  APB2 peripheral clock enable register
    APB2ENR: u32,
    reserved80: [8]u8,
    ///  AHB1 peripheral clock enable in low power mode register
    AHB1LPENR: u32,
    ///  AHB2 peripheral clock enable in low power mode register
    AHB2LPENR: u32,
    ///  AHB3 peripheral clock enable in low power mode register
    AHB3LPENR: u32,
    reserved96: [4]u8,
    ///  APB1 peripheral clock enable in low power mode register
    APB1LPENR: u32,
    ///  APB2 peripheral clock enabled in low power mode register
    APB2LPENR: u32,
    reserved112: [8]u8,
    ///  Backup domain control register
    BDCR: u32,
    ///  clock control & status register
    CSR: u32,
    reserved128: [8]u8,
    ///  spread spectrum clock generation register
    SSCGR: u32,
    ///  PLLI2S configuration register
    PLLI2SCFGR: u32,
};
