const fmt = @import("std").fmt;
const Writer = @import("std").io.Writer;

const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;
const VGA_SIZE = VGA_WIDTH * VGA_HEIGHT;

pub const ConsoleColors = enum(u8) {
    Black = 0,
    Blue = 1,
    Green = 2,
    Cyan = 3,
    Red = 4,
    Magenta = 5,
    Brown = 6,
    LightGray = 7,
    DarkGray = 8,
    LightBlue = 9,
    LightGreen = 10,
    LightCyan = 11,
    LightRed = 12,
    LightMagenta = 13,
    LightBrown = 14,
    White = 15,
};

var row: usize = 0;
var column: usize = 0;
var color = vgaEntryColor(ConsoleColors.LightGray, ConsoleColors.Black);
var buffer = @as([*]volatile u16, @ptrFromInt(0xB8000));

fn vgaEntryColor(fg: ConsoleColors, bg: ConsoleColors) u8 {
    return @intFromEnum(fg) | (@intFromEnum(bg) << 4);
}

fn vgaEntry(uc: u8, new_color: u8) u16 {
    const c: u16 = new_color;

    return uc | (c << 8);
}

pub fn initialize() void {
    clear();
}

pub fn setPosition(x: usize, y: usize) bool {
    if (x < VGA_WIDTH and y < VGA_HEIGHT) {
        column = x;
        row = y;
        return true;
    }
    return false;
}

pub fn setColor(new_color: u8) void {
    color = new_color;
}

pub fn clear() void {
    @memset(buffer[0..VGA_SIZE], vgaEntry(' ', color));
}

pub fn putCharAt(c: u8, new_color: u8, x: usize, y: usize) void {
    const index = y * VGA_WIDTH + x;
    buffer[index] = vgaEntry(c, new_color);
}

pub fn putChar(c: u8) void {
    putCharAt(c, color, column, row);
    column += 1;
    if (column == VGA_WIDTH) {
        column = 0;
        row += 1;
        if (row == VGA_HEIGHT)
            row = 0;
    }
}

pub fn puts(data: []const u8) void {
    for (data) |c|
        putChar(c);
}

pub const writer = Writer(void, error{}, callback){ .context = {} };

fn callback(_: void, string: []const u8) error{}!usize {
    puts(string);
    return string.len;
}

pub fn printf(comptime format: []const u8, args: anytype) void {
    fmt.format(writer, format, args) catch unreachable;
}

pub fn newLine() void {
    column = 0;
    row += 1;
    if (row == VGA_HEIGHT)
        row = 0;
}

pub fn getCharRaw() u8 {
    return asm volatile (
        \\ inb $0x60, %[out] 
        : [out] "=al" (-> u8),
          //: [dev] "d" (0x60),
    );
}

//pub fn run

pub fn getAsciiChar() ?u8 {
    return getAsciiCharFromCode(getCharRaw());
}

fn getAsciiCharFromCode(key_code: u8) ?u8 {
    return switch (key_code) {
        0x1E => 'A',
        0x30 => 'B',
        0x2E => 'C',
        0x20 => 'D',
        0x12 => 'E',
        0x21 => 'F',
        0x22 => 'G',
        0x23 => 'H',
        0x17 => 'I',
        0x24 => 'J',
        0x25 => 'K',
        0x26 => 'L',
        0x32 => 'M',
        0x31 => 'N',
        0x18 => 'O',
        0x19 => 'P',
        0x10 => 'Q',
        0x13 => 'R',
        0x1F => 'S',
        0x14 => 'T',
        0x16 => 'U',
        0x2F => 'V',
        0x11 => 'W',
        0x2D => 'X',
        0x15 => 'Y',
        0x2C => 'Z',
        0x02 => '1',
        0x03 => '2',
        0x04 => '3',
        0x05 => '4',
        0x06 => '5',
        0x07 => '6',
        0x08 => '7',
        0x09 => '8',
        0x0A => '9',
        0x0B => '0',
        0x0C => '-',
        0x0D => '=',
        0x1A => '[',
        0x1B => ']',
        0x27 => ';',
        0x2B => '\\',
        0x33 => ',',
        0x34 => '.',
        0x35 => '/',
        0x39 => ' ',
        else => null,
    };
}

pub const Key = enum(u8) {
    BacktickDown = 0x29,
    BacktickUp = 0xA9,
    EscDown = 0x01,
    EscUp = 0x81,
    Key1Down = 0x02,
    Key1Up = 0x82,
    Key2Down = 0x03,
    Key2Up = 0x83,
    Key3Down = 0x04,
    Key3Up = 0x84,
    Key4Down = 0x05,
    Key4Up = 0x85,
    Key5Down = 0x06,
    Key5Up = 0x86,
    Key6Down = 0x07,
    Key6Up = 0x87,
    Key7Down = 0x08,
    Key7Up = 0x88,
    Key8Down = 0x09,
    Key8Up = 0x89,
    Key9Down = 0x0A,
    Key9Up = 0x8A,
    Key0Down = 0x0B,
    Key0Up = 0x8B,
    MinusDown = 0x0C,
    MinusUp = 0x8C,
    EqualDown = 0x0D,
    EqualUp = 0x8D,
    BackspaceDown = 0x0E,
    BackspaceUp = 0x8E,
    TabDown = 0x0F,
    TabUp = 0x8F,
    QDown = 0x10,
    QUp = 0x90,
    WDown = 0x11,
    WUp = 0x91,
    EDown = 0x12,
    EUp = 0x92,
    RDown = 0x13,
    RUp = 0x93,
    TDown = 0x14,
    TUp = 0x94,
    YDown = 0x15,
    YUp = 0x95,
    UDown = 0x16,
    UUp = 0x96,
    IDown = 0x17,
    IUp = 0x97,
    ODown = 0x18,
    OUp = 0x98,
    PDown = 0x19,
    PUp = 0x99,
    OpenBracketDown = 0x1A,
    OpenBracketUp = 0x9A,
    CloseBracketDown = 0x1B,
    CloseBracketUp = 0x9B,
    EnterDown = 0x1C,
    EnterUp = 0x9C,
    LCtrlDown = 0x1D,
    LCtrlUp = 0x9D,
    // RCtrlDown = 0x1D,
    // RCtrlUp = 0x9D,
    ADown = 0x1E,
    AUp = 0x9E,
    SDown = 0x1F,
    SUp = 0x9F,
    DDown = 0x20,
    DUp = 0xA0,
    FDown = 0x21,
    FUp = 0xA1,
    GDown = 0x22,
    GUp = 0xA2,
    HDown = 0x23,
    HUp = 0xA3,
    JDown = 0x24,
    JUp = 0xA4,
    KDown = 0x25,
    KUp = 0xA5,
    LDown = 0x26,
    LUp = 0xA6,
    SemicolonDown = 0x27,
    SemicolonUp = 0xA7,
    ApostropheDown = 0x28,
    ApostropheUp = 0xA8,
    LShiftDown = 0x2A,
    LShiftUp = 0xAA,
    ZDown = 0x2C,
    ZUp = 0xAC,
    XDown = 0x2D,
    XUp = 0xAD,
    CDown = 0x2E,
    CUp = 0xAE,
    VDown = 0x2F,
    VUp = 0xAF,
    BDown = 0x30,
    BUp = 0xB0,
    NDown = 0x31,
    NUp = 0xB1,
    MDown = 0x32,
    MUp = 0xB2,
    CommaDown = 0x33,
    CommaUp = 0xB3,
    DotDown = 0x34,
    DotUp = 0xB4,
    SlashDown = 0x35,
    SlashUp = 0xB5,
    RShiftDown = 0x36,
    RShiftUp = 0xB6,
    KeypadMulDown = 0x37,
    KeypadMulUp = 0xB7,
    AltDown = 0x38,
    AltUp = 0xB8,
    SpaceDown = 0x39,
    SpaceUp = 0xB9,
    CapsLockDown = 0x3A,
    CapsLockUp = 0xBA,
    F1Down = 0x3B,
    F1Up = 0xBB,
    F2Down = 0x3C,
    F2Up = 0xBC,
    F3Down = 0x3D,
    F3Up = 0xBD,
    F4Down = 0x3E,
    F4Up = 0xBE,
    F5Down = 0x3F,
    F5Up = 0xBF,
    F6Down = 0x40,
    F6Up = 0xC0,
    F7Down = 0x41,
    F7Up = 0xC1,
    F8Down = 0x42,
    F8Up = 0xC2,
    F9Down = 0x43,
    F9Up = 0xC3,
    F10Down = 0x44,
    F10Up = 0xC4,
    F11Down = 0x57,
    F11Up = 0xd7,
    F12Down = 0x58,
    F12Up = 0xd8,
    NumLockDown = 0x45,
    NumLockUp = 0xC5,
    ScrollLockDown = 0x46,
    ScrollLockUp = 0xC6,
    //KeypadDivideDown = 0x35,
    //KeypadDivideUp = 0xB5,
    KeypadMinusDown = 0x4A,
    KeypadMinusUp = 0xCA,
    Keypad7Down = 0x47,
    Keypad7Up = 0xC7,
    Keypad8Down = 0x48,
    Keypad8Up = 0xC8,
    Keypad9Down = 0x49,
    Keypad9Up = 0xC9,
    Keypad4Down = 0x4B,
    Keypad4Up = 0xCB,
    Keypad5Down = 0x4C,
    Keypad5Up = 0xCC,
    Keypad6Down = 0x4D,
    Keypad6Up = 0xCD,
    KeypadPlusDown = 0x4E,
    KeypadPlusUp = 0xCE,
    Keypad1Down = 0x4F,
    Keypad1Up = 0xCF,
    Keypad2Down = 0x50,
    Keypad2Up = 0xD0,
    Keypad3Down = 0x51,
    Keypad3Up = 0xD1,
    Keypad0Down = 0x52,
    Keypad0Up = 0xD2,
    KeypadDotDown = 0x53,
    KeypadDotUp = 0xD3,
    //KeypadEnterDown = 0x1C,
    //KeypadEnterUp = 0x9C,
};
//del,   \,     right alt, meta, calc, page up/down, home end,    all arrow keys up down left right
//53 d3, 2b ab,   38 98     , 5b db,21 a1, 49 c9 51 d1, 47 c7 4f cf, 48 c8 50 d0 4b cb 4d cd
