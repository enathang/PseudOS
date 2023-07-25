_test_write_hello_init:
	la a0, test_result_00
	push
	call _write_uart
	pop

	push
	call _write_hello_init
	pop

	ret


_test_write_register_to_uart_literal:
	# Should be 0
	la a0, test_result_10
	push
	call _write_uart
	pop

	li a0, 0
	li a1, 0
	li a2, 63
	push
	call _write_register_to_uart_literal
	pop

	# Should be 0b...000011110
	la a0, test_result_11
	push
	call _write_uart
	pop
	
	li a0, 30
	li a1, 0
	li a2, 63
	push
	call _write_register_to_uart_literal
	pop

	# Should be all 1s
	la a0, test_result_12
	push
	call _write_uart
	pop

	li a0, 0xFFFFFFFFFFFFFFFF
	li a1, 0
	li a2, 63
	push
	call _write_register_to_uart_literal
	pop

	ret
