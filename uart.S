
# Assumes 0-terminated string address is loaded into a0
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

