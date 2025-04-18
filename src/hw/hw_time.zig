export fn rdtsc() u64 {
    // The low 32 bits go into EAX, the high 32 into EDX.
    var low: u32 = undefined;
    var high: u32 = undefined;

    asm volatile ("rdtsc"
        : [low_out] "={eax}" (low), // output #1
          [high_out] "={edx}" (high), // output #2
    );

    // Combine high/low into a 64‑bit result:
    return (@as(u64, high) << 32) | @as(u64, low);
}
