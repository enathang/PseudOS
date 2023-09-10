	.file	"main.c"
	.option nopic
	.attribute arch, "rv64i2p0_m2p0_a2p0_f2p0_d2p0_c2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.section	.rodata
	.align	3
.LC0:
	.string	"Hello from c_main!"
	.string	""
	.text
	.align	1
	.globl	c_main
	.type	c_main, @function
c_main:
	addi	sp,sp,-16
	sd	ra,8(sp)
	sd	s0,0(sp)
	addi	s0,sp,16
	lui	a5,%hi(.LC0)
	addi	a0,a5,%lo(.LC0)
	call	_write_uart
	nop
	ld	ra,8(sp)
	ld	s0,0(sp)
	addi	sp,sp,16
	jr	ra
	.size	c_main, .-c_main
	.align	1
	.globl	c_add
	.type	c_add, @function
c_add:
	addi	sp,sp,-32
	sd	ra,24(sp)
	sd	s0,16(sp)
	addi	s0,sp,32
	mv	a5,a0
	mv	a4,a1
	sb	a5,-17(s0)
	mv	a5,a4
	sb	a5,-18(s0)
	lbu	a5,-18(s0)
	andi	a5,a5,0xff
	bne	a5,zero,.L3
	lbu	a5,-17(s0)
	j	.L4
.L3:
	lbu	a5,-18(s0)
	addiw	a5,a5,-1
	andi	a4,a5,0xff
	lbu	a5,-17(s0)
	mv	a1,a4
	mv	a0,a5
	call	c_add
	mv	a5,a0
	addiw	a5,a5,1
	andi	a5,a5,0xff
.L4:
	mv	a0,a5
	ld	ra,24(sp)
	ld	s0,16(sp)
	addi	sp,sp,32
	jr	ra
	.size	c_add, .-c_add
	.section	.rodata
	.align	3
.LC1:
	.string	"Next fibonacci number is: "
	.string	""
	.align	3
.LC2:
	.string	"\n"
	.string	""
	.text
	.align	1
	.globl	fibonacci
	.type	fibonacci, @function
fibonacci:
	addi	sp,sp,-64
	sd	ra,56(sp)
	sd	s0,48(sp)
	addi	s0,sp,64
	sd	a0,-40(s0)
	sd	a1,-48(s0)
	sd	a2,-56(s0)
	sd	zero,-32(s0)
	j	.L6
.L7:
	ld	a4,-40(s0)
	ld	a5,-48(s0)
	add	a5,a4,a5
	sd	a5,-24(s0)
	ld	a5,-48(s0)
	sd	a5,-40(s0)
	ld	a5,-24(s0)
	sd	a5,-48(s0)
	ld	a5,-32(s0)
	addi	a5,a5,1
	sd	a5,-32(s0)
.L6:
	ld	a4,-32(s0)
	ld	a5,-56(s0)
	bltu	a4,a5,.L7
	lui	a5,%hi(.LC1)
	addi	a0,a5,%lo(.LC1)
	call	_write_uart_wrapper
	li	a2,63
	li	a1,0
	ld	a0,-24(s0)
	call	_write_register_to_uart_literal_wrapper
	lui	a5,%hi(.LC2)
	addi	a0,a5,%lo(.LC2)
	call	_write_uart_wrapper
	ld	a5,-24(s0)
	mv	a0,a5
	ld	ra,56(sp)
	ld	s0,48(sp)
	addi	sp,sp,64
	jr	ra
	.size	fibonacci, .-fibonacci
	.ident	"GCC: (g2ee5e430018-dirty) 12.2.0"
