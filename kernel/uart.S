# Writes (potentially formatted) 0-terminated string to uart
# Symbols: %b will print a register value in binary
#          %h will print a register value in hex
#          %s will print a register value in short-binary (8 bits)
# a0 = address of string
# a1...a3 = registers to print out
# a7 = index (should not be used)
.globl _write_uart_formatted
.align 12
_write_uart_formatted:
	mv a6, a2
	li a7, 0
	j _write_uart_formatted_loop

	_write_uart_formatted_loop:
		lb t1, (a0) # Load byte from string
		beqz t1, _write_uart_formatted_ret # If 0-termination char is reached, finish

		li t4, 0x25 # ascii % char
		beq t1, t4, _write_uart_formatted_special_char

		li t0, 0x10000000
		sb t1, (t0) # Write byte to UART
		j _write_uart_formatted_increment

	_write_uart_formatted_special_char:
		# Increment and read in next byte
		li t2, 1
		add a0, a0, t2
		lb t2, (a0) #t2 now contains the type of formatting to do

		# Get value from register
		li t4, 0
		beq a7, t4, _write_uart_formatted_first_param
		li t4, 1
		beq a7, t4, _write_uart_formatted_second_param
		li t4, 2
		beq a7, t4, _write_uart_formatted_third_param
		# Can expand in future

	_write_uart_formatted_first_param:
		mv t5, a1
		j _write_uart_formatted_char
	_write_uart_formatted_second_param:
		mv t5, a6
		j _write_uart_formatted_char
	_write_uart_formatted_third_param:
		mv t5, a3
		j _write_uart_formatted_char

	# Assumes t2 contains the format type
	# Assumes t5 contains the register to format
	_write_uart_formatted_char:
		# Increment a7
		li t6, 1
		add a7, a7, t6

		li t4, 0x68 # h in ascii
		beq t2, t4, _write_uart_formatted_hex
		li t4, 0x73 # s in ascii
		beq t2, t4, _write_uart_formatted_short
		# Otherwise, default to print in binary
		j _write_uart_formatted_binary

	_write_uart_formatted_hex:
		push
		mv a0, t5
		call _write_register_to_uart_hex
		pop

		j _write_uart_formatted_increment
	_write_uart_formatted_binary:
		push
		mv a0, t5
		li a1, 0
		li a2, 63
		call _write_register_to_uart_binary
		pop

		j _write_uart_formatted_increment
	_write_uart_formatted_short:
		push
		mv a0, t5
		li a1, 0
		li a2, 5
		call _write_register_to_uart_binary
		pop

		j _write_uart_formatted_increment

	_write_uart_formatted_increment:
		li t2, 1 # Increment string addr to point to next byte
		add a0, t2, a0
		j _write_uart_formatted_loop # Continue looping


	_write_uart_formatted_ret:
		ret

# Writes (potentially formatted) 0-terminated string to uart
# Symbols: %b will print a register value in binary
#          %h will print a register value in hex
#          %s will print a register value in short-binary (8 bits)
# a0 = address of string
.globl _write_uart
.align 12
_write_uart:
	lb t1, (a0) # Load byte from string
	beqz t1, _write_uart_ret # If 0-termination char is reached, finish

	# If char is $, output value of a1 as a register binary value
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
		call _write_register_to_uart_binary
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
.globl _write_register_to_uart_binary
_write_register_to_uart_binary:
	bgt a1, a2, _write_register_to_uart_binary_end

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
	j _write_register_to_uart_binary

	_write_register_to_uart_binary_end:
		ret

# a0 = byte to turn to hex
# return a2 ascii hex symbol for byte
_byte_to_hex:
	li t0, 0xA
	blt a0, t0, _byte_to_hex_num
	j _byte_to_hex_letter

	_byte_to_hex_num:
		li t0, 0x30 # ascii offset for 0
		add a2, a0, t0
		ret

	_byte_to_hex_letter:
		li t0, 0x37 # ascii offset for A-0xA
		add a2, a0, t0
		ret


.globl _write_register_to_uart_hex
_write_register_to_uart_hex:
	li a1, 15
	li a3, 0
	j _write_register_to_uart_hex_main

	_write_register_to_uart_hex_main:
		blt a1, a3, _write_register_to_uart_hex_end
		
		# Write hex to uart
		mv t0, a0
		li t2, 4
		mul t2, t2, a1
		sra t0, t0, t2
		
		li t1, 0xF
		and t1, t0, t1 # Grab lowest hex only
			
		push
		mv a0, t1
		call _byte_to_hex
		pop
	
		push
		mv a0, a2
		call _write_byte_to_uart
		pop

		# Increment bit counter
		li t1, -1
		add a1, a1, t1
		j _write_register_to_uart_hex_main

	_write_register_to_uart_hex_end:
		ret


.globl _write_register_to_uart_hex_wrapper
_write_register_to_uart_hex_wrapper:
	mv t0, a2
	push
	call _write_register_to_uart_hex
	pop
	mv a2, t0

	ret


.globl _write_uart_wrapper
_write_uart_wrapper:
	mv t0, a2
	push
	call _write_uart
	pop
	mv a2, t0

	ret

.globl _write_register_to_uart_binary_wrapper
_write_register_to_uart_binary_wrapper:
	mv t0, a2
	push
	call _write_register_to_uart_binary
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

