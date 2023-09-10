	.file	"elf.c"
	.option nopic
	.attribute arch, "rv64i2p0_m2p0_a2p0_f2p0_d2p0_c2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.globl	ELF_MAGIC_NUMBER
	.section	.sdata,"aw"
	.align	2
	.type	ELF_MAGIC_NUMBER, @object
	.size	ELF_MAGIC_NUMBER, 4
ELF_MAGIC_NUMBER:
	.word	1179403647
	.section	.rodata
	.align	3
.LC0:
	.string	"Attempted to load ELF binary, but magic number was not correct. Skipping it.\n"
	.string	""
	.align	3
.LC1:
	.string	"\nph.ptype: "
	.string	""
	.align	3
.LC2:
	.string	"\nSize to allocate: "
	.string	""
	.align	3
.LC3:
	.string	"\nCan't load into memory because of ph.ptype: "
	.string	""
	.align	3
.LC4:
	.string	"Finished parse_elf, returning..."
	.string	""
	.text
	.align	1
	.globl	parse_elf
	.type	parse_elf, @function
parse_elf:
	addi	sp,sp,-208
	sd	ra,200(sp)
	sd	s0,192(sp)
	addi	s0,sp,208
	sd	a0,-200(s0)
	ld	a5,-200(s0)
	ld	a7,0(a5)
	ld	a6,8(a5)
	ld	a0,16(a5)
	ld	a1,24(a5)
	ld	a2,32(a5)
	ld	a3,40(a5)
	ld	a4,48(a5)
	ld	a5,56(a5)
	sd	a7,-128(s0)
	sd	a6,-120(s0)
	sd	a0,-112(s0)
	sd	a1,-104(s0)
	sd	a2,-96(s0)
	sd	a3,-88(s0)
	sd	a4,-80(s0)
	sd	a5,-72(s0)
	lw	a4,-128(s0)
	lui	a5,%hi(ELF_MAGIC_NUMBER)
	lw	a5,%lo(ELF_MAGIC_NUMBER)(a5)
	beq	a4,a5,.L2
	lui	a5,%hi(.LC0)
	addi	a0,a5,%lo(.LC0)
	call	_write_uart_wrapper
.L2:
	sw	zero,-20(s0)
	j	.L3
.L6:
	ld	a4,-96(s0)
	lw	a5,-20(s0)
	lhu	a3,-74(s0)
	mul	a5,a5,a3
	add	a5,a4,a5
	ld	a4,-200(s0)
	add	a5,a4,a5
	ld	a6,0(a5)
	ld	a0,8(a5)
	ld	a1,16(a5)
	ld	a2,24(a5)
	ld	a3,32(a5)
	ld	a4,40(a5)
	ld	a5,48(a5)
	sd	a6,-184(s0)
	sd	a0,-176(s0)
	sd	a1,-168(s0)
	sd	a2,-160(s0)
	sd	a3,-152(s0)
	sd	a4,-144(s0)
	sd	a5,-136(s0)
	lui	a5,%hi(.LC1)
	addi	a0,a5,%lo(.LC1)
	call	_write_uart_wrapper
	lw	a5,-184(s0)
	slli	a5,a5,32
	srli	a5,a5,32
	li	a2,63
	li	a1,0
	mv	a0,a5
	call	_write_register_to_uart_literal_wrapper
	lw	a5,-184(s0)
	mv	a4,a5
	li	a5,1
	bne	a4,a5,.L4
	ld	a5,-144(s0)
	sd	a5,-40(s0)
	ld	a5,-168(s0)
	sd	a5,-48(s0)
	lw	a5,-180(s0)
	slli	a5,a5,32
	srli	a5,a5,32
	sd	a5,-56(s0)
	lui	a5,%hi(.LC2)
	addi	a0,a5,%lo(.LC2)
	call	_write_uart_wrapper
	li	a2,63
	li	a1,0
	ld	a0,-40(s0)
	call	_write_register_to_uart_literal_wrapper
	call	_kalloc
	sd	a0,-64(s0)
	ld	a1,-64(s0)
	ld	a0,-48(s0)
	call	_map_virtual_address_to_physical_address
	j	.L5
.L4:
	lui	a5,%hi(.LC3)
	addi	a0,a5,%lo(.LC3)
	call	_write_uart_wrapper
	lw	a5,-184(s0)
	slli	a5,a5,32
	srli	a5,a5,32
	li	a2,63
	li	a1,0
	mv	a0,a5
	call	_write_register_to_uart_literal_wrapper
.L5:
	lw	a5,-20(s0)
	addiw	a5,a5,1
	sw	a5,-20(s0)
.L3:
	lhu	a5,-72(s0)
	sext.w	a4,a5
	lw	a5,-20(s0)
	sext.w	a5,a5
	blt	a5,a4,.L6
	lui	a5,%hi(.LC4)
	addi	a0,a5,%lo(.LC4)
	call	_write_uart_wrapper
	ld	a5,-104(s0)
	sd	a5,-32(s0)
	ld	a5,-32(s0)
	mv	a0,a5
	ld	ra,200(sp)
	ld	s0,192(sp)
	addi	sp,sp,208
	jr	ra
	.size	parse_elf, .-parse_elf
	.ident	"GCC: (g2ee5e430018-dirty) 12.2.0"
