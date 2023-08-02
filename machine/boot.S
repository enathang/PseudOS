.option norvc

.include "kernel/constants.S"
.include "kernel/macro.S"
.include "kernel/paging.S"
#.include "kernel/tests.S"
.include "kernel/uart.S"
.include "kernel/pci.S"
.include "kernel/vga.S"
.include "kernel/kernel.S"
.include "user/user.S"

.align 12
.section .data 

.align 12
_stack:
	.skip 4096, 0

_root_page_table:
	.skip 4096, 0

.section .text.init
.global _start


_start: 
	csrr t0, mhartid
	bnez t0,  _child_init
	j _main_init

_main_init:
	# Initialize stack pointer
	la sp, _stack

	# Load mtvec to print a warning
	la t0, _machine_trap
	csrw mtvec, t0
	la t0, _supervisor_trap
	csrw stvec, t0

	# Call hello world
	push
	call _write_hello_init
	pop

	push
	#call _unit_tests
	pop

	push
	call _output_mode
	pop	

	# Print out hardware info
	push
	call _output_hardware_info_entry
	pop
	
	push
	call _move_to_supervisor_mode
	pop
	
	wfi

_child_init:
	la a0, child_hart
	csrr a1, mhartid
	# call _write_uart
	ret


_machine_trap:
	push
	call _machine_trap_handler
	pop

	wfi
	_machine_trap_handler:
		csrr t0, mcause
		beq t0, zero, _machine_trap_handler_instruction_misaligned

		li t1, 1
		beq t0, t1, _machine_trap_handler_instruction_access_fault

		li t1, 2
		beq t0, t1, _machine_trap_handler_illegal_instruction_fault

		li t1, 5
		beq t0, t1, _machine_trap_handler_load_access_fault

		li t1, 12
		beq t0, t1, _machine_trap_handler_instruction_page_fault

		li t1, 15
		beq t0, t1, _machine_trap_handler_store_amo_page_fault

		j _machine_trap_handler_uncoded_exception

	_machine_trap_handler_instruction_misaligned:
		la a0, machine_trap_instruction_misaligned_warning
		csrr a1, mtval
		j _machine_trap_handler_write_uart

	_machine_trap_handler_instruction_access_fault:
		la a0, machine_trap_instruction_access_fault_warning
		csrr a1, mtval
		j _machine_trap_handler_write_uart

	_machine_trap_handler_illegal_instruction_fault:
		la a0, machine_trap_handler_illegal_instruction_fault_warning
		csrr a1, mtval
		push
		call _write_uart
		pop

		ret

	_machine_trap_handler_load_access_fault:
		la a0, machine_trap_load_access_fault_warning	
		csrr a1, mtval
		j _machine_trap_handler_write_uart

	_machine_trap_handler_instruction_page_fault:
		la a0, machine_trap_instruction_page_fault_warning
		csrr a1, mtval
		push
		call _write_uart
		pop 
		
		ret

	_machine_trap_handler_store_amo_page_fault:
		la a0, machine_trap_handler_store_amo_page_fault_warning
		csrr a1, mtval
		push
		call _write_uart
		pop

		ret

	_machine_trap_handler_uncoded_exception:
		la a0, machine_trap_warning
		csrr a1, mcause
		csrr a2, mtval

		debug_csr_reg mtval 

		j _machine_trap_handler_write_uart

	_machine_trap_handler_write_uart:
		push
		call _write_uart
		pop

		ret


_supervisor_trap:
	la a0, supervisor_trap_warning
	csrr a1, scause
	csrr a2, stval
	push
	call _write_uart
	pop
	
	wfi

_output_hardware_info_entry:
	print bootup_machine_hardware_info

	csrr t0, misa
	li t1, 1       # Bit mask
	li t2, 0x40    # Ascii 'A'-1 offset to convert 1 to A, 2 to B etc.
	li t3, 26      # Number of bits to check
	li t4, 1       # Number of bits checked so far

	j _output_hardware_info

	_output_hardware_info:
		# Base case return
		bgt t4, t3, _output_hardware_info_end

		# Find out if nth bit is 0 or 1
		and t5, t1, t0
		# Load corresponding letter into a0
		add a0, t4, t2
		# If 1, write out a0 to uart
		bgt t5, zero, _conditional_uart_write
		j _after_uart_write

	_conditional_uart_write:
		push
		li t0, 0x10000000
		sb a0, (t0)
		pop
		j _after_uart_write
	
	_after_uart_write:
		# Move mask over 1 bit
		slli t1, t1, 1
		li t5, 1
		add t4, t4, t5

		# loop
		j _output_hardware_info

	_output_hardware_info_end:
		ret


_move_to_supervisor_mode:
	print bootup_launch_into_supervisor_mode

	#.extern c_main
	#call c_main

	#.extern c_add
	#li a0, 0
	#li a1, 64
	#call c_add
	#debug_reg a0

	# la t0, _supervisor_mode_entry
	la t0, _supervisor_mode_entry #0x0000000000
	csrw sepc, t0
	csrw mepc, t0
	
	# Add X,W,R permissions to physical memory protection register 0 config
	li t0, 15 # 8 + 4 + 2 + 1
	csrw pmpcfg0, t0
	li t0, 0x8000000000000
	csrw pmpaddr0, t0
	
	# Set sstatus's SPP bit to be 1
	csrr t0, mstatus
	li t1, 1
	slli t1, t1, 8
	or t0, t0, t1
	csrw mstatus, t0
	
	# Set mstatus's SPP bit to be 1
	csrr t0, mstatus
	
	# clear bits
	li t1, 3
	slli t1, t1, 11
	not t1, t1
	and t0, t0, t1

	# set bits
	li t2, 1
	slli t2, t2, 11
	or t0, t0, t2

	csrw mstatus, t0

	push
	call _setup_page_table
	pop

	# Map virtual address 0s to be the physical address of supervisor_entry
	push
	call _map_supervisor_virtual_addresses
	pop


	# Jump to MPP mode (which should be supervisor mode)
	push
	la a0, jump_into_supervisor_mode
	call _write_uart
	pop

	push
	call _list_pci_ecam
	pop

	mret

	ret


_setup_page_table:
	# Print out that we're starting to create root page table
	print create_root_page_table

	# Set root page table address into satp
	push
	call _kalloc_wrapper
	pop
	mv t0, a2
	li t1, 4096
	div t0, t0, t1
	# Sets mode in satp to be 8, which is Sv39 (39-bit virtual addressing)
	li t1, 8
	slli t1, t1, 60

	add t0, t0, t1
	csrw satp, t0

	ret


_map_supervisor_virtual_addresses:
	print map_supervisor_virtual_addresses_message

	push
	la a0, _supervisor_mode_entry
	la a1, _supervisor_mode_entry
	call _map_virtual_address_to_physical_address
	pop

	push
	la a0, _data_start
	la a1, _data_start
	call _map_virtual_address_to_physical_address
	pop

	push
	la a0, supervisor_mode_welcome
	la a1, supervisor_mode_welcome
	call _map_virtual_address_to_physical_address
	pop


	push
	li a0, 0x10000000 # This is the UART memory-mapped location in QEMU
	li a1, 0x10000000
	call _map_virtual_address_to_physical_address
	pop

	push
	la a0, _write_uart
	la a1, _write_uart
	call _map_virtual_address_to_physical_address
	pop

	push
	la a0, _elf_start
	la a1, _elf_start
	call _map_virtual_address_to_physical_address
	pop
	
	push
	la a0, _stack
	la a1, _stack
	call _map_virtual_address_to_physical_address
	pop

	push
	la a0, _write_register_to_uart_literal
	la a1, _write_register_to_uart_literal
	call _map_virtual_address_to_physical_address
	pop

	ret


_output_mode:
	print bootup_output_mode

	csrr t0, mstatus
	srai t0, t0, 14
	li t1, 3
	and a1, t0, t1
	la a0, machine_mode
	
	push
	call _write_uart
	pop

	ret

_write_hartid:
	csrr a1, mhartid
	j _write_uart


_wait:
	wfi

