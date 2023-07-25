.option norvc
.section .data 

.include "macro.S"
.include "paging.S"
.include "tests.S"

# Welcomes
welcome: .ascii "Welcome to PseudOS\n\0"
supervisor_mode_welcome: .ascii "Welcome to Supervisor Mode \n\0"
user_mode_welcome: .ascii "Welcome to User Mode \n\0"

# Machine info messages
child_hart: .ascii "I am a child hart % s \0"
machine_mode: .ascii "Mode: % \n\0"

# Bootup steps
bootup_output_mode: .ascii "\n===== Checking msource register for current permission mode =====\n\0"
bootup_machine_hardware_info: .ascii "\n===== Checking misa register for hardware info =====\n\0"
bootup_launch_into_supervisor_mode: .ascii "\n===== Launching into supervisor mode =====\n\0"
create_root_page_table: .ascii "\n===== Create root page table =====\n\0"
jump_into_supervisor_mode: .ascii "\n===== Jump into supervisor mode =====\n\0"
supervisor_pte_message: .ascii "\nPage table entry for supervisor mode entry is: \n\0"
supervisor_physical_page_message: .ascii "\nPhysical address for supervisor mode entry is: \n\0"

# Unit tests helper strings
begin_unit_test_message: .ascii "\n===== Beginning unit tests =====\n\0"
test_result_00: .ascii "\nShould print 'Welcome to PseudOS':\n\0"
test_result_10: .ascii "\nShould be 0b00..000: \n\0"
test_result_11: .ascii "\nShould be 0b00..01110:\n\0"
test_result_12: .ascii "\nShould be all 1s:\n\0"
end_unit_test_message: .ascii "\n===== End unit tests =====\n\0"

# Trap error messages go here
machine_trap_instruction_misaligned_warning: .ascii "Machine trap: instruction misaligned. Value: % \n\0"
machine_trap_instruction_access_fault_warning: .ascii "Machine trap: instruction access fault. Value % \n\0"
machine_trap_handler_illegal_instruction_fault_warning: .ascii "Machine trap: illegal instruction. Register binary is: \n\0"
machine_trap_instruction_page_fault_warning: .ascii "Machine trap: instruction page fault. Virtual page address % \n Register binary is: \n\0"
machine_trap_load_access_fault_warning: .ascii "Machine trap: load access fault. Virtual page address % \n\0"
machine_trap_warning: .ascii "Warning, machine trap. Exception code: %, mtval: & \n Consider adding a specific handler for this trap. \n\0"

supervisor_trap_warning: .ascii "Warning, supervisor trap. Exception code: %, mtval: & \n\0"

# Misc
number_char: .ascii "%\0"
newline: .ascii "\n\0"
debugging_message: .ascii "\nDebugging: \n\0"

_scratchpad:
	.skip 1024

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
	call _unit_tests
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

_unit_tests:
	push
	la a0, begin_unit_test_message
	call _write_uart
	pop

	push
	call _test_write_register_to_uart_literal
	pop
	
	push
	call _test_write_hello_init
	pop

	push
	la a0, end_unit_test_message
	call _write_uart
	pop


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

		# li t1, 2
		#beq t0, t1, _machine_trap_handler_illegal_instruction_fault

		li t1, 5
		beq t0, t1, _machine_trap_handler_load_access_fault

		li t1, 12
		beq t0, t1, _machine_trap_handler_instruction_page_fault

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
		la a1, machine_trap_handler_illegal_instruction_fault_warning
		csrr a1, mtval
		push
		call _write_uart
		pop

		#push
		#csrr a0, mtval
		#li a1, 0
		#li a2, 63
		#call _write_register_to_uart_literal
		#pop

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
		
		push
		csrr a0, mtval
		li a1, 0
		li a2, 63
		call _write_register_to_uart_literal
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
	push
	la a0, bootup_machine_hardware_info
	call _write_uart
	pop

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
	push
	la a0, bootup_launch_into_supervisor_mode 
	call _write_uart	
	pop

	# la t0, _supervisor_mode_entry
	li t0, 0x0000000000
	csrw sepc, t0
	csrw mepc, t0
	
	# Add X,W,R permissions to physical memory protection register 0 config
	li t0, 15 # 8 + 4 + 2 + 1
	csrw pmpcfg0, t0
	li t0, 0x80000000
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

	# Print out that we're starting to create root page table
	push
	la a0, create_root_page_table
	call _write_uart
	pop

	# Set root page table address into satp
	call _kalloc
	mv t0, a2 # la t0, (_root_page_table)
	li t1, 4096
	div t0, t0, t1
	# Sets mode in satp to be 8, which is Sv39 (39-bit virtual addressing)
	li t1, 8
	slli t1, t1, 60

	add t0, t0, t1
	csrw satp, t0

	# Map virtual address 0s to be the physical address of supervisor_entry
	li a0, 0x0000000000
	la a1, _supervisor_mode_entry
	# li a2, 0b000 # rwx bits are all 0
	push
	#call _map_virtual_to_physical_page
	call _map_virtual_address_to_physical_address
	pop

	# Jump to MPP mode (which should be supervisor mode)
	push
	la a0, jump_into_supervisor_mode
	call _write_uart
	pop

	mret

	ret

# Function to output 64 register value bit-by-bit to UART
# a0 = register value to write out
# a1 = bit to start reading from
# a2 = bit to read through
_write_register_to_uart_literal:
	bgt a1, a2, _write_register_to_uart_literal_end

	# Write bit to uart
	sub t1, a2, a1
	sra t0, a0, t1
	li t1, 1
	and t2, t0, t1 # Grab lowest bit only
	
	push
	# la a0, number_char
	# mv a1, t2
	mv a0, t2
	li t0, 0x30
	add a0, a0, t0
	call _write_byte_to_uart
	pop

	# Increment bit counter
	li t1, 1
	add a1, a1, t1
	j _write_register_to_uart_literal

	_write_register_to_uart_literal_end:
		ret

_debug_call:
	push
	call _write_hello_init
	pop

	ret

.align 12
_supervisor_mode_entry:
	ecall
	la a0, supervisor_mode_welcome
	call _write_uart
	wfi


_user_mode_entry:
	la a0, user_mode_welcome
	call _write_uart
	wfi


_output_mode:
	push
	la a0, bootup_output_mode
	call _write_uart
	pop

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


# Assumes 0-terminated string address is loaded into a0
_write_uart:
	lb t1, (a0) # Load byte from string
	beqz t1, _write_uart_ret # If 0-termination char is reached, finish

	# if char is %, output value of a1 to uart instead of %
	li t4, 0x25
	beq t1, t4, _write_uart_param

	# if char is &, output value of a2 to uart instead of &
	li t4, 0x26
	beq t1, t4, _write_uart_second_param

	li t0, 0x10000000
	sb t1, (t0) # Write byte to UART

	j _write_uart_increment

	_write_uart_param:
		# Add 0x30 to param to turn into ascii (assuming number)
		li t1, 0x30
		add a1, t1, a1
		sb a1, (t0)

		j _write_uart_increment

	_write_uart_second_param:
		li t1, 0
		add a2, t1, a2
		sb a2, (t0)

		j _write_uart_increment

	_write_uart_increment:
		li t2, 1 # Increment string addr to point to next byte
		add a0, t2, a0
		j _write_uart # Continue looping


	_write_uart_ret:
		ret

# Writes a byte to UART
# a0 = byte to write
_write_byte_to_uart:
	li t0, 0x10000000 # UART addr
	sb a0, (t0)
	ret


_write_hello_init:
	la a1, welcome
	li t2, 0x10000000
	j _write_hello

	_write_hello:
		# Load first byte into register
		lb t1, (a1)
		beqz t1, _write_hello_end
		# Write byte to UART memory address
		sb t1, (t2)
		li t3, 1
		add a1, t3, a1
		j _write_hello
		# If the byte is not 0, repeat
	_write_hello_end:
		ret

_wait:
	wfi
