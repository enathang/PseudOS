.option norvc
.section .data 

welcome: .ascii "Welcome to PseudOS\n\0"
child_hart: .ascii "I am a child hart % s \0"
machine_mode: .ascii "Mode: % \n\0"
machine_trap_warning: .ascii "Warning, machine trap. Exception code: %, mtval: & \n\0"
supervisor_trap_warning: .ascii "Warning, supervisor trap. Exception code: %, mtval: & \n\0"
supervisor_mode_welcome: .ascii "Welcome to Supervisor Mode \n\0"
user_mode_welcome: .ascii "Welcome to User Mode \n\0"

_scratchpad:
	.skip 1024

_stack:
	.skip 2048, 0

.section .text.init
.global _start

.macro push
	# Push ra, t0-3, and a0-1 onto stack
	sd ra, 0(sp)
	sd t0, 8(sp)
	sd t1, 16(sp)
	sd t2, 24(sp)
	sd t3, 32(sp)
	sd a0, 40(sp)
	sd a1, 48(sp)

	li t0, 56
	add sp, t0, sp
.endm

.macro pop
	li t0, -56
	add sp, t0, sp

	ld ra, 0(sp) # Why does this need to be double and not just word?
	ld t0, 8(sp)
	ld t1, 16(sp)
	ld t2, 24(sp)
	ld t3, 32(sp)
	ld a0, 40(sp)
	ld a1, 48(sp)
.endm

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
	call _output_mode
	pop	

	# Print out hardware info
	push
	call _output_hardware_info_entry
	pop
	
	push
	call _move_to_supervisor_mode
	pop

	# Call hello world
	push
	call _write_hello_init
	pop
	
	wfi

_child_init:
	la a0, child_hart
	csrr a1, mhartid
	# call _write_uart
	ret


_machine_trap:
	la a0, machine_trap_warning
	csrr a1, mcause
	csrr a2, mtval
	push
	call _write_uart
	pop

	wfi

_supervisor_trap:
	la a0, supervisor_trap_warning
	csrr a1, scause
	csrr a2, stval
	push
	call _write_uart
	pop
	
	wfi

_output_hardware_info_entry:
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
	la t0, _supervisor_mode_entry
	csrw sepc, t0

	#la t0, _user_mode_entry
	#csrw uepc, t0

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
	
	# Jump to SPP mode (which should be supervisor mode)
	sret

	ret

_supervisor_mode_entry:
	la a0, supervisor_mode_welcome
	call _write_uart
	wfi


_user_mode_entry:
	la a0, user_mode_welcome
	call _write_uart
	wfi


_output_mode:
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
	li t0, 0x10000000 # Store UART addr
	lb t1, (a0) # Load byte from string
	beqz t1, _write_uart_ret # If 0-termination char is reached, finish

	# if char is %, output value of a1 to uart instead of %
	li t4, 0x25
	sub t3, t1, t4
	beqz t3, _write_uart_param

	# if char is &, output value of a2 to uart instead of &
	li t4, 0x26
	sub t3, t1, t4
	beqz t3, _write_uart_second_param

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
