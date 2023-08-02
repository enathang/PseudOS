# .define PTE_SIZE 8

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

.macro print str
	push
	la a0, \str
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
