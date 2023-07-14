.option norvc
.section .data 

welcome: .ascii "Welcome to PseudOS\0"

.section .text.init
.global _start

_start: 
	csrr t0, 0xF14
	bnez t0,  _child_init
	j _main_init
	wfi

_main_init:
	j _write_hello_init
	ret

_child_init:
	j _write_uart_two
	ret


_write_uart_two:
	li t1, 0x62
	li t2, 0x10000000
	sw t1, (t2)
	ret

_write_uart:
	li t1, 0x61
	li t2, 0x10000000
	sw t1, (t2)
	ret

_write_hello_init:
	la a1, welcome
	li t2, 0x10000000 
	j _write_hello
	ret


_write_hello:
	# Load first byte into register
	lb t1, (a1)
	beqz t1, _wait
	# Write byte to UART memory address
	sb t1, (t2)
	li t3, 1
	add a1, t3, a1
	j _write_hello
	# If the byte is not 0, repeat

_wait:
	wfi
