

.align 12
_supervisor_mode_entry:
	la a0, supervisor_mode_welcome
	lb t0, (a0)
	li t1, 0x10000000
	call _write_uart
	
	# Load elf file and jump to user mode
	.extern parse_elf
	la a0, _elf_start
	push
	call parse_elf
	mv a2, a0
	pop

	# a2 now contains the entry point to our ELF file
	mv a0, a2
	j _move_to_user_mode

# a0 = entry point for user mode
_move_to_user_mode:
	# Set SPP bit to 0
	# Set sepc to a0

	#
	sret
