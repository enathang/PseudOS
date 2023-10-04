pseudOS: machine/boot.S user/main.c
	# Commands required for the linter
	# riscv64-unknown-elf-gcc -include kernel/macro.S -E machine/boot.S -o build/boot_macros.S	

	# Build kernel
	riscv64-unknown-elf-gcc -c user/main.c -o build/main.o -mcmodel=medany
	riscv64-unknown-elf-gcc -c kernel/elf.c -o build/elf.o -mcmodel=medany
	riscv64-unknown-elf-gcc -c machine/dump.c -o build/dump.o -mcmodel=medany
	riscv64-unknown-elf-gcc -c -O0 machine/boot.S -o build/boot.o -mcmodel=medany
	riscv64-unknown-elf-gcc -c kernel/paging.c -o build/paging.o -mcmodel=medany
	
	# Build example ELF program and add to kernel
	riscv64-unknown-elf-gcc -c user/add.c -o build/add.o -O0 -mcmodel=medany
	riscv64-unknown-elf-ld build/add.o -o build/add.elf
	riscv64-unknown-elf-objcopy --add-section .elf=build/add.elf build/boot.o build/boot.o
	
	# Build kernel
	riscv64-unknown-elf-ld build/boot.o build/main.o build/dump.o build/elf.o build/paging.o -T kernel/kernel.lds -o build/kernel.elf
	
	# Run QEMU	
	qemu-system-riscv64 -machine virt -cpu rv64 -smp 4 -m 128M  -serial mon:stdio -bios none -kernel build/kernel.elf -device VGA

pseudOS_debug: machine/boot.S user/main.c
	# Commands required for the linter
	# riscv64-unknown-elf-gcc -g -O0 -include kernel/macro.S -E machine/boot.S -o build/boot_macros.S	

	# Build kernel
	riscv64-unknown-elf-gcc -g -O0 -c user/main.c -o build/main.o -mcmodel=medany
	riscv64-unknown-elf-gcc -g -O0  -c kernel/elf.c -o build/elf.o -mcmodel=medany
	riscv64-unknown-elf-gcc -g -O0  -c machine/dump.c -o build/dump.o -mcmodel=medany
	riscv64-unknown-elf-gcc -g -O0  -c -O0 machine/boot.S -o build/boot.o -mcmodel=medany
	
	# Build example ELF program and add to kernel
	riscv64-unknown-elf-gcc -c user/add.c -o build/add.o -O0 -mcmodel=medany
	riscv64-unknown-elf-ld build/add.o -o build/add.elf
	riscv64-unknown-elf-objcopy --add-section .elf=build/add.elf build/boot.o build/boot.o
	
	# Build kernel
	riscv64-unknown-elf-ld build/boot.o build/main.o build/dump.o build/elf.o -T kernel/kernel.lds -o build/kernel.elf
	
	# Run QEMU	
	qemu-system-riscv64 -machine virt -cpu rv64 -smp 4 -m 128M  -serial mon:stdio -bios none -kernel build/kernel.elf -device VGA -gdb tcp::9000 -S


