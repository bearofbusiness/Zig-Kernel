//! hw/ps2_io.zig
export fn getCharRaw() u8 {
    return asm volatile (
        \\ inb $0x60, %[out] 
        : [out] "=al" (-> u8),
          //: [dev] "d" (0x60),
    );
}
