pseudOS: boot.S main.c
	riscv64-unknown-elf-gcc -c main.c -o main.o -mcmodel=medany
	riscv64-unknown-elf-gcc -c boot.S -o boot.o
	riscv64-unknown-elf-ld boot.o main.o -T kernel.lds -o kernel.elf
	qemu-system-riscv64 -machine virt -cpu rv64 -smp 4 -m 128M  -serial mon:stdio -bios none -kernel kernel.elf -device VGA
