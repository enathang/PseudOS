.macro push
	# :+ ra, t0, t1, t2, t3, a0, a1
	# Push ra, t0-3, and a0-1 onto stack
	sd ra, -8(sp)
	sd t0, -16(sp)
	sd t1, -24(sp)
	sd t2, -32(sp)
	sd t3, -40(sp)
	sd a0, -48(sp)
	sd a1, -56(sp)

	li t0, -56
	add sp, t0, sp
.endm

.macro pop
	# :- ra, t0, t1, t2, t3, a0, a1
	li t0, 56
	add sp, t0, sp

	ld ra, -8(sp) # Why does this need to be double and not just word?
	ld t0, -16(sp)
	ld t1, -24(sp)
	ld t2, -32(sp)
	ld t3, -40(sp)
	ld a0, -48(sp)
	ld a1, -56(sp)
.endm

.macro print str
	push
	la a0, \str
	call _write_uart
	pop
.endm

.macro prints str reg
	push
	la a0, \str
	mv a1, \reg
	call _write_uart
	pop
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
	call _write_register_to_uart_binary
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
	call _write_register_to_uart_binary
	pop

	print_newline
.endm

.macro print_newline
	push
	la a0, newline
	call _write_uart
	pop
.endm
