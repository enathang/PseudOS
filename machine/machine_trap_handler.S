

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

		li t1, 13
		beq t0, t1, _machine_trap_handler_load_page_fault

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
		
		push
		call _write_uart_formatted
		pop
		ret
		#j _machine_trap_handler_write_uart

	_machine_trap_handler_instruction_page_fault:
		la a0, machine_trap_instruction_page_fault_warning
		csrr a1, mtval
		
		push
		call _write_uart_formatted
		pop 

		.extern dump_heap
		push
		la a0, _heap_end
		call dump_heap
		pop
	
		print dump_page_table_message
		.extern dump_page_table
		push
		la a0, _root_page_table
		li a1, 0
		li a2, 2
		call dump_page_table
		pop	
		
		ret
	_machine_trap_handler_load_page_fault:
		la a0, machine_trap_handler_load_page_fault_warning
		csrr a1, mtval
		push
		call _write_uart_formatted
		pop

		print dump_heap_message
		.extern dump_heap
		push
		la a0, _heap_end
		call dump_heap
		pop

		print dump_page_table_message
		.extern dump_page_table
		push
		la a0, _root_page_table
		li a1, 0
		li a2, 2
		call dump_page_table
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


