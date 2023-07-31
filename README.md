# PseudOS

PseudOS is a toy operating system based on the following resources:
 - https://www.youtube.com/watch?v=s_4tFz52jbc
 - xv6


## Prerequisites
PseudOS runs on QEMU and needs a riscv64 toolchain to compile

## Compiling the bootloader
`riscv64-unknown-elf-as boot.S -o boot.o`
`riscv64-unknown-elf-ld boot.o -T kernel.lds -o kernel.elf`
Run with `qemu-system-riscv64 -machine virt -cpu rv64 -smp 4 -m 128M -nographic -serial mon:stdio -bios none -kernel kernel.elf`

or all together
` riscv64-unknown-elf-as boot.S -o boot.o; riscv64-unknown-elf-ld boot.o -T kernel.lds -o kernel.elf; qemu-system-riscv64 -machine virt -cpu rv64 -smp 4 -m 128M -nographic -serial mon:stdio -bios none -kernel kernel.elf`

to run with graphics
`riscv64-unknown-elf-as boot.S -o boot.o; riscv64-unknown-elf-ld boot.o -T kernel.lds -o kernel.elf; qemu-system-riscv64 -machine virt -cpu rv64 -smp 4 -m 128M  -serial mon:stdio -bios none -kernel kernel.elf -device VGA`

