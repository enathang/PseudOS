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

	push
	call _test_stack
	pop

	ret



_test_write_hello_init:
	la a0, test_result_00
	push
	call _write_uart
	pop

	print welcome_message

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


_test_stack:
	.extern fibonacci
	push
	li a0, 0
	li a1, 1
	li a2, 24
	call fibonacci
	mv a2, a0
	pop
	push
	mv a0, a2
	call _write_register_to_uart_literal
	pop

	ret
