
# Assumes 0-terminated string address is loaded into a0
.globl _write_uart
.align 12
_write_uart:
	lb t1, (a0) # Load byte from string
	beqz t1, _write_uart_ret # If 0-termination char is reached, finish

	# If char is $, output value of a1 as a register value
	li t4, 0x24
	beq t1, t4, _write_uart_register

	# if char is %, output value of a1 to uart instead of %
	li t4, 0x25
	beq t1, t4, _write_uart_param

	# if char is &, output value of a2 to uart instead of &
	li t4, 0x26
	beq t1, t4, _write_uart_second_param

	li t0, 0x10000000
	sb t1, (t0) # Write byte to UART

	j _write_uart_increment

	_write_uart_register:
		push
		mv a0, a1
		li a1, 0
		li a2, 63
		call _write_register_to_uart_literal
		pop

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

# Function to output 64 register value bit-by-bit to UART
# a0 = register value to write out
# a1 = bit to start reading from
# a2 = bit to read through
.globl _write_register_to_uart_literal
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


.globl _write_uart_wrapper
_write_uart_wrapper:
	mv t0, a2
	push
	call _write_uart
	pop
	mv a2, t0

	ret

.globl _write_register_to_uart_literal_wrapper
_write_register_to_uart_literal_wrapper:
	mv t0, a2
	push
	call _write_register_to_uart_literal
	pop
	mv a2, t0

	ret

# Writes a byte to UART
# a0 = byte to write
.globl _write_byte_to_uart
_write_byte_to_uart:
	li t0, 0x10000000 # UART addr
	sb a0, (t0)
	ret

