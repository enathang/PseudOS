.macro push
	li t0, -56
	add sp, t0, sp
	
	sd ra, 0(sp)
	sd t0, 8(sp)
	sd t1, 16(sp)
	sd t2, 24(sp)
	sd t3, 32(sp)
	sd a0, 40(sp)
	sd a1, 48(sp)
.endm

.macro pop
	ld ra, 0(sp)
	ld t0, 8(sp)
	ld t1, 16(sp)
	ld t2, 24(sp)
	ld t3, 32(sp)
	ld a0, 40(sp)
	ld a1, 48(sp)

	li t0, 56
	add sp, t0, sp
.endm

.macro debug_reg reg_name
	push
	la a0, debugging_message
	call _write_uart
	pop

	push
	mv a0, \reg_name
	li a1, 0
	li a2, 63
	call _write_register_to_uart_literal
	pop

	print_newline
.endm


.macro debug_csr_reg reg_name
	push
	la a0, debugging_message
	call _write_uart
	pop

	push
	csrr a0, \reg_name
	li a1, 0
	li a2, 63
	call _write_register_to_uart_literal
	pop

	print_newline
.endm

.macro print_newline
	push
	la a0, newline
	call _write_uart
	pop
.endm
