# 0 "machine/boot.S"
# 1 "/Users/nathangifford/Desktop/Projects/2023/pseudOS//"
# 0 "<built-in>"
# 0 "<command-line>"
# 1 "./kernel/macro.S" 1
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
# 0 "<command-line>" 2
# 1 "machine/boot.S"
.option norvc

.include "kernel/macro.S"
.include "kernel/constants.S"
.include "kernel/uart.S"
.include "kernel/pci.S"
.include "kernel/vga.S"
.include "user/user.S"

.align 12
.section .data

.align 12
_stack_buffer:
 .skip 4096, 0

# Note: currently the stack grows towards lower-addresses. Therefore, it actually grows
# into _stack_buffer and not _stack.

.align 12
_stack:
 .skip 4096, 0

_root_page_table:
 .skip 4096, 0

.section .text.init
.global _start


_start:
 csrr t0, mhartid
 bnez t0, _child_init
 j _main_init

_main_init:
 .option push
 .option norelax
 la gp, _data_start
 li t0, 0x800
 add gp, gp, t0
 .option pop

 # Initialize stack pointer
 la sp, _stack

 # Load mtvec to print a warning
 la t0, _machine_trap
 csrw mtvec, t0
 la t0, _supervisor_trap
 csrw stvec, t0

 # Call hello world
 print welcome_message

 push
 call _output_mode
 pop

 # Print out hardware info
 push
 call _output_hardware_info_entry
 pop

 push
 call _unit_tests
 pop

 push
 call _move_to_supervisor_mode
 pop

 wfi

_child_init:
 la a0, child_hart
 csrr a1, mhartid
 # call _write_uart
 ret

.include "machine/machine_trap_handler.S"
.include "tests/tests.S"
.include "kernel/kernel.S"
.include "kernel/paging.S"


_supervisor_trap:
 la a0, supervisor_trap_warning
 csrr a1, scause
 csrr a2, stval
 push
 call _write_uart
 pop

 wfi


_output_hardware_info_entry:
 print bootup_machine_hardware_info

 csrr t0, misa
 li t1, 1 # Bit mask
 li t2, 0x40 # Ascii 'A'-1 offset to convert 1 to A, 2 to B etc.
 li t3, 26 # Number of bits to check
 li t4, 1 # Number of bits checked so far

 j _output_hardware_info

 _output_hardware_info:
  # Base case return
  bgt t4, t3, _output_hardware_info_end

  # Find out if nth bit is 0 or 1
  and t5, t1, t0
  # Load corresponding letter into a0
  add a0, t4, t2
  # If 1, write out a0 to uart
  bgt t5, zero, _conditional_uart_write
  j _after_uart_write

 _conditional_uart_write:
  push
  li t0, 0x10000000
  sb a0, 0(t0)
  pop
  j _after_uart_write

 _after_uart_write:
  # Move mask over 1 bit
  slli t1, t1, 1
  li t5, 1
  add t4, t4, t5

  # loop
  j _output_hardware_info

 _output_hardware_info_end:
  ret


_move_to_supervisor_mode:
 print bootup_launch_into_supervisor_mode

 la t0, _supervisor_mode_entry
 csrw sepc, t0
 csrw mepc, t0

 # Add X,W,R permissions to physical memory protection register 0 config
 li t0, 15 # 8 + 4 + 2 + 1
 csrw pmpcfg0, t0
 li t0, 0x8000000000000
 csrw pmpaddr0, t0

 # Set mstatus's SPP bit to be 1
 csrr t0, mstatus
 li t1, 1
 slli t1, t1, 8
 or t0, t0, t1
 csrw mstatus, t0

 # Set mstatus's SPP bit to be 1
 csrr t0, mstatus

 # clear bits
 li t1, 3
 slli t1, t1, 11
 not t1, t1
 and t0, t0, t1

 # set bits
 li t2, 1
 slli t2, t2, 11
 or t0, t0, t2

 csrw mstatus, t0

 push
 call _setup_page_table
 pop

 # Map virtual address 0s to be the physical address of supervisor_entry
 push
 call _map_supervisor_virtual_addresses
 pop


 # Jump to MPP mode (which should be supervisor mode)
 push
 la a0, jump_into_supervisor_mode
 call _write_uart
 pop

 push
 call _list_pci_ecam
 pop

 mret

 ret


_setup_page_table:
 # Print out that we're starting to create root page table
 print create_root_page_table

 # Set root page table address into satp
 la t0, _root_page_table
 li t1, 4096
 div t0, t0, t1

 # Sets mode in satp to be 8, which is Sv39 (39-bit virtual addressing)
 li t1, 8
 slli t1, t1, 60

 add t0, t0, t1
 csrw satp, t0






 # Add new level-0 page table
 push
 call _kalloc_wrapper
 pop
 mv t4, a2 # t4 now contains base address for page table
 mv s0, t4

 # === write level-0 page table into itself ===
 push
 mv a0, t4
 li a1, 0b111
 call _convert_physical_address_to_pte
 pop
 mv t5, a2 # t5 now contains PTE

 # Get PTE address for level-0 page table
 srai t0, t4, 12
 li t1, 0x1FF
 and t0, t0, t1 # should be PTE index
 li t1, 8
 mul t0, t0, t1 # multiply by page size to get PTE offset
 add t0, t0, t4 # add PT base address to get PTE address
 sd t5, 0(t0) # Store PTE for page table 0 at PTE address

 # === Add a new level-1 page table ===
 push
 call _kalloc_wrapper
 pop
 mv t4, a2 #t4 now contains address of page table
 mv s1, t4

 # === write level-1 page table to level-0 page table ===
 push
 mv a0, t4
 li a1, 0b111
 call _convert_physical_address_to_pte
 pop
 mv t5, a2 # t5 now contains PTE

 # Add level-1 page table to level-0 page table (code should look very similar to above :) )
 srai t0, t4, 12
 li t1, 0x1FF
 and t0, t0, t1 # should be PTE index
 li t1, 8
 mul t0, t0, t1 # multiply by page size to get PTE offset
 add t0, t0, s0 # add PT base address to get PTE address
 sd t5, 0(t0) # Store PTE for page table 0 at PTE address

 # === Add level-2 page table to level-0 page table ===
 la t4, _root_page_table

 push
 mv a0, t4
 li a1, 0b111
 call _convert_physical_address_to_pte
 pop
 mv t5, a2 # t5 now contains PTE

 # Add level-2 page table to level-0 page table (again, code is basically repeated )
 srai t0, t4, 12
 li t1, 0x1FF
 and t0, t0, t1 # should be PTE index
 li t1, 8
 mul t0, t0, t1 # multiply by page size to get PTE offset
 add t0, t0, s0 # add PT base address to get PTE address
 sd t5, 0(t0) # Store PTE for page table 0 at PTE address



 # === Add level-0 page table to level-1-page table
 # s0 contains level 0 page table address
 push
 mv a0, s0
 li a1, 0b000
 call _convert_physical_address_to_pte
 pop
 mv t5, a2

 mv t4, s0
 srai t0, t4, 21
 li t1, 0x1FF
 and t0, t0, t1 # should be PTE index
 li t1, 8
 mul t0, t0, t1 # multiply by page size to get PTE offset
 add t0, t0, s1 # add PT base address to get PTE address
 sd t5, 0(t0) # Store PTE for page table 0 at PTE address

 # === Add level-2 page table to level-1-page table
 # s0 contains level 0 page table address
 push
 la a0, _root_page_table
 li a1, 0b000
 call _convert_physical_address_to_pte
 pop
 mv t5, a2

 la t4, _root_page_table
 srai t0, t4, 21
 li t1, 0x1FF
 and t0, t0, t1 # should be PTE index
 li t1, 8
 mul t0, t0, t1 # multiply by page size to get PTE offset
 add t0, t0, s1 # add PT base address to get PTE address
 sd t5, 0(t0) # Store PTE for page table 0 at PTE address





 # === Add level-1 page table to level 2 page table
 #mv t4, s1
 #push
 #mv a0, t4
 #li a1, 0b000
 #call _convert_physical_address_to_pte
 #pop
 #mv t5, a2 # t5 now contains PTE

 # Add level-1 page table to level-2 page table
 #la t6, _root_page_table
 #srai t0, t4, 30
 #li t1, 0x1FF
 #and t0, t0, t1 # should be PTE index
 #li t1, 8
 #mul t0, t0, t1 # multiply by page size to get PTE offset
 #add t0, t0, t6 # add PT base address to get PTE address
 #sd t5, (t0) # Store PTE for page table 0 at PTE address


 # === Add level-2 page table to level 2 page table
 #la t4, _root_page_table
 #push
 #mv a0, t4
 #li a1, 0b000
 #call _convert_physical_address_to_pte
 #pop
 #mv t5, a2 # t5 now contains PTE

 # Add level-1 page table to level-2 page table
 #la t6, _root_page_table
 #srai t0, t4, 30
 #li t1, 0x1FF
 #and t0, t0, t1 # should be PTE index
 #li t1, 8
 #mul t0, t0, t1 # multiply by page size to get PTE offset
 #add t0, t0, t6 # add PT base address to get PTE address
 #sd t5, (t0) # Store PTE for page table 0 at PTE address*/





 # Map addresses
 push
 la a0, _root_page_table
 la a1, _root_page_table
 li a2, 0b0111
 call _map_virtual_address_to_physical_address
 pop
# 398 "machine/boot.S"
 ret


_map_supervisor_virtual_addresses:
 print map_supervisor_virtual_addresses_message

 push
 la a0, _supervisor_mode_entry
 la a1, _supervisor_mode_entry
 li a2, 0b0111
 call _map_virtual_address_to_physical_address
 pop

 push
 la a0, _data_start
 la a1, _data_start
 li a2, 0b0111
 call _map_virtual_address_to_physical_address
 pop

 push
 la a0, supervisor_mode_welcome
 la a1, supervisor_mode_welcome
 li a2, 0b0111
 call _map_virtual_address_to_physical_address
 pop

 push
 li a0, 0x10000000 # This is the UART memory-mapped location in QEMU
 li a1, 0x10000000
 la a2, 0b0111
 call _map_virtual_address_to_physical_address
 pop

 push
 la a0, _write_uart
 la a1, _write_uart
 li a2, 0b0111
 call _map_virtual_address_to_physical_address
 pop

 push
 la a0, _write_uart_formatted
 la a1, _write_uart_formatted
 li a2, 0b0111
 call _map_virtual_address_to_physical_address
 pop

 push
 la a0, _elf_start
 la a1, _elf_start
 li a2, 0b0111
 call _map_virtual_address_to_physical_address
 pop

 push
 la a0, _stack
 la a1, _stack
 li a2, 0b0111
 call _map_virtual_address_to_physical_address
 pop

 push
 la a0, _stack_buffer
 la a1, _stack_buffer
 li a2, 0b0111
 call _map_virtual_address_to_physical_address
 pop

 push
 la a0, _heap_counter
 la a1, _heap_counter
 la a2, 0b0111
 call _map_virtual_address_to_physical_address
 pop

 push
 la a0, _heap_end
 la a1, _heap_end
 la a2, 0b0111
 call _map_virtual_address_to_physical_address
 pop

 push
 la a0, _write_register_to_uart_binary
 la a1, _write_register_to_uart_binary
 la a2, 0b0111
 call _map_virtual_address_to_physical_address
 pop

 ret


_output_mode:
 print bootup_output_mode

 csrr t0, mstatus
 srai t0, t0, 14
 li t1, 3
 and a1, t0, t1
 la a0, machine_mode

 push
 call _write_uart
 pop

 ret

_write_hartid:
 csrr a1, mhartid
 j _write_uart


_wait:
 wfi
