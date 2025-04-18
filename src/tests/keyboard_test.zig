const std = @import("std");
const expectEqual = std.testing.expectEqual;

const kb = @import("keyboard"); // contains getKey, Key, KeyCodeRaw
usingnamespace kb;

// holds the feed
var feed: []const u8 = &[_]u8{};
var pos: usize = 0;

export fn getCharRaw() u8 {
    const b = feed[pos];
    pos += 1;
    return b;
}

// for reseting the global byte stream before each test
fn setFeed(bytes: []const u8) void {
    feed = bytes;
    pos = 0;
}

// Tests
test "single-byte: A down" {
    setFeed(&[_]u8{0x1E});
    try expectEqual(kb.Key.ADown, kb.getKey().key);
}

test "single-byte: Esc up" {
    setFeed(&[_]u8{0x81});
    try expectEqual(kb.Key.EscUp, kb.getKey().key);
}

test "E0 prefix: Numpad Enter down" {
    // 0xE0 0x1C  ->  NumpadEnterDown
    setFeed(&[_]u8{ 0xE0, 0x1C });
    try expectEqual(kb.Key.NumpadEnterDown, kb.getKey().key);
}

test "E0 prefix: Home down" {
    // 0xE0 0x47  ->  HomeDown
    setFeed(&[_]u8{ 0xE0, 0x47 });
    try expectEqual(kb.Key.HomeDown, kb.getKey().key);
}

test "Print-Screen make  (E0 2A E0 37)" {
    setFeed(&[_]u8{ 0xE0, 0x2A, 0xE0, 0x37 });
    try expectEqual(kb.Key.PrintScreenDown, kb.getKey().key);
}

test "Print-Screen break (E0 B7 E0 AA)" {
    setFeed(&[_]u8{ 0xE0, 0xB7, 0xE0, 0xAA });
    try expectEqual(kb.Key.PrintScreenUp, kb.getKey().key);
}

test "Pause/Break make (E1 1D 45 E1 9D C5)" {
    setFeed(&[_]u8{ 0xE1, 0x1D, 0x45, 0xE1, 0x9D, 0xC5 });
    try expectEqual(kb.Key.PauseBreakDown, kb.getKey().key);
}

test "unknown sequence -> Unknown" {
    // 0xE0 0x81  (0x81 isn’t a legal Set‑2 code) if it is not a legal Set-1 code it will fail
    setFeed(&[_]u8{ 0xE0, 0x81 });
    try expectEqual(kb.Key.Unknown, kb.getKey().key);
}

test "exhaustive 1-byte -> Key mapping" {
    inline for (std.meta.fields(kb.KeyCodeRaw)) |f| {
        const raw_variant = @field(kb.KeyCodeRaw, f.name);
        if (raw_variant != kb.KeyCodeRaw.ExtendedKey and
            raw_variant != kb.KeyCodeRaw.SpecialExtendedKey and
            raw_variant != kb.KeyCodeRaw.LeftGuiDown and
            raw_variant != kb.KeyCodeRaw.RightGuiDown and
            raw_variant != kb.KeyCodeRaw.LeftGuiUp and
            raw_variant != kb.KeyCodeRaw.RightGuiUp and
            raw_variant != kb.KeyCodeRaw.ApplicationsDown and
            raw_variant != kb.KeyCodeRaw.ApplicationsUp)
        {
            setFeed(&[_]u8{@intFromEnum(raw_variant)});

            const expected_key = @field(kb.Key, f.name);

            const key = kb.getKey().key;
            // std.log.warn("\n{} == {}\n", .{ expected_key, key });
            try expectEqual(expected_key, key);
        }
    }
}
