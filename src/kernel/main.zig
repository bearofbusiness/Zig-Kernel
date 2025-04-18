const console = @import("./console.zig");
const keyboard = @import("./keyboard.zig");

const ALIGN = 1 << 0;
const MEMINFO = 1 << 1;
const MAGIC = 0x1BADB002;
const FLAGS = ALIGN | MEMINFO;

const MultibootHeader = packed struct {
    magic: i32 = MAGIC,
    flags: i32,
    checksum: i32,
    padding: u32 = 0,
};

export var multiboot: MultibootHeader align(4) linksection(".multiboot") = .{
    .flags = FLAGS,
    .checksum = -(MAGIC + FLAGS),
};

var stack_bytes: [16 * 1024]u8 align(16) linksection(".bss") = undefined;

// We specify that this function is "naked" to let the compiler know
// not to generate a standard function prologue and epilogue, since
// we don't have a stack yet.
export fn _start() callconv(.Naked) noreturn {
    // We use inline assembly to set up the stack before jumping to
    // our kernel main.
    asm volatile (
        \\ movl %[stack_top], %%esp
        \\ movl %%esp, %%ebp
        \\ call %[kmain:P]
        :
        // The stack grows downwards on x86, so we need to point ESP
        // to one element past the end of `stack_bytes`.
        //
        // Unfortunately, we can't just compute `&stack_bytes[stack_bytes.len]`,
        // as the Zig compiler will notice the out-of-bounds access
        // at compile-time and throw an error.
        //
        // We can instead take the start address of `stack_bytes` and
        // add the size of the array to get the one-past-the-end
        // pointer. However, Zig disallows pointer arithmetic on all
        // pointer types except "multi-pointers" `[*]`, so we must cast
        // to that type first.
        //
        // Finally, we pass the whole expression as an input operand
        // with the "immediate" constraint to force the compiler to
        // encode this as an absolute address. This prevents the
        // compiler from doing unnecessary extra steps to compute
        // the address at runtime (especially in Debug mode), which
        // could possibly clobber registers that are specified by
        // multiboot to hold special values (e.g. EAX).
        : [stack_top] "i" (@as([*]align(16) u8, @ptrCast(&stack_bytes)) + @sizeOf(@TypeOf(stack_bytes))),
          // We let the compiler handle the reference to kmain by passing it as an input operand as well.
          [kmain] "X" (&kmain),
    );
}

extern fn rdtsc() u64;

fn kmain() callconv(.C) void {
    console.initialize();
    console.puts("Hello Zig Kernel!");
    console.newLine();
    console.puts("Hello Zig Kernel!");
    console.newLine();
    var old_char: keyboard.Key = .Unknown;
    while (true) {
        const raw_n = keyboard.getKeyUsingState();
        const raw = if (raw_n) |ra| ra else continue;
        if (raw.key != old_char) {
            //_ = console.setPosition(0, 2);

            if (console.getPosition().y > 15) {
                console.clear();
                _ = console.setPosition(0, 0);
            }
            console.printf("{}", .{raw.key});
            console.newLine();
            old_char = raw.last_key;

            if (raw.key == .ADown) {
                console.printf("{}", .{rdtsc() / 60 / 60 / 24 / 365});
                console.newLine();
            }

            if (raw.key == .EscUp) {
                console.clear();
                _ = console.setPosition(0, 0);
            }
        }
    }

    //no return
    while (true) {
        asm volatile (
            \\hlt
        );
    }
}

fn threadTest() void {
    console.puts("Hello Zig Kernel from thread!");
}
