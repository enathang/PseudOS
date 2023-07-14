# PseudOS

Inspired by/following https://www.youtube.com/watch?v=s_4tFz52jbc

Run with qemu-system-riscv64 -machine virt -cpu rv64 -smp 4 -m 128M -nographic -serial mon:stdio -bios none -kernel kernel.elf

## Compiling
'riscv64-unknown-elf-as boot.S -o boot.o'
'riscv64-unknown-elf-ld boot.o -T kernel.lds -o kernel.elf'
