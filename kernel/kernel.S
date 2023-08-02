

.align 12
_supervisor_mode_entry:
	la a0, supervisor_mode_welcome
	lb t0, (a0)
	li t1, 0x10000000
	call _write_uart
	
	.extern parse_elf
	la a0, _elf_start
	push
	call parse_elf
	pop

	# a0 now contains the entry point to our ELF file
	jalr a0
	
	wfi

