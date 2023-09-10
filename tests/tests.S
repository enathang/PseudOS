_unit_tests:
	push
	la a0, begin_unit_test_message
	call _write_uart
	pop

	push
	call _test_write_register_to_uart_binary
	pop

	push
	call _test_write_register_to_uart_hex	
	pop
	
	push
	call _test_write_hello_init
	pop

	push
	call _test_stack
	pop

	push
	call _test_dump_page_table
	pop
	
	push
	la a0, end_unit_test_message
	call _write_uart
	pop

	ret



_test_write_hello_init:
	la a0, test_result_00
	push
	call _write_uart
	pop

	print welcome_message

	ret


_test_write_register_to_uart_binary:
	# Should be 0
	la a0, test_result_10
	push
	call _write_uart
	pop

	li a0, 0
	li a1, 0
	li a2, 63
	push
	call _write_register_to_uart_binary
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
	call _write_register_to_uart_binary
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
	call _write_register_to_uart_binary
	pop

	ret

_test_write_register_to_uart_hex:
	la a0, test_result_12
	push
	call _write_uart
	pop

	li a0, 0xFFFF0123DEADBEEF
	push
	call _write_register_to_uart_hex
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
	call _write_register_to_uart_binary
	pop

	ret

_test_dump_page_table:
	.extern dump_page_table 
	push
	la a0, _root_page_table
	li a1, 0
	li a2, 2
	call dump_page_table
	pop

	ret
