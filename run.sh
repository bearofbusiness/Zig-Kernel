zig build || exit 1
cp zig-out/bin/kernel.elf ./iso/boot/
grub-mkrescue -o zig-kernel.iso iso || exit 1
qemu-system-i386 -cdrom zig-kernel.iso