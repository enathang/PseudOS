
# kalloc
# Inputs: none
# return: a0, the physical address of new 4kB page
.globl _kalloc
_kalloc:
	# Increment heap counter
	la t1, _heap_counter
	lb t0, (t1)

	li t2, 1
	add t0, t0, t2
	sb t0, (t1)

	# get address of new page based on heap counter
	li t2, 4096
	mul t0, t0, t2

	# return address
	la t1, _heap_end
	sub a0, t1, t0
	ret

# A wrapper around kalloc to conform to my ABI, so I can switch kalloc to standard ABI
_kalloc_wrapper:
	push
	call _kalloc
	mv a2, a0
	pop
	
	ret

# a0 = physical address
# a1 = rwx bits
# return: a2, PTE for physical address
_convert_physical_address_to_pte:
	# debug_reg a0

	# Zero out bits before physical address and address offset
	li t1, 0x00FFFFFFFFFFF000
	and t0, a0, t1

	# Shift physical address to correct position in PTE
	srai t0, t0, 2

	# shift rwx bits to correct position in PTE
	slli t1, a1, 1
	or t0, t0, t1

	# set valid bit to 1 in PTE
	li t1, 1
	or t0, t0, t1

	# Return PTE as a2
	mv a2, t0

	# debug_reg a2

	ret


# a0 = PTE
# return: a2, physical address
_get_physical_address_from_pte:
	# Zero out any unneeded bits
	li t1, 0x003FFFFFFFFFFC00
	and t0, a0, t1

	# Shift address into correct place
	slli t0, t0, 2

	# return physical address as a2
	mv a2, t0

	ret


# a0 = virtual address
# a1 = physical address
.globl _map_virtual_address_to_physical_address
_map_virtual_address_to_physical_address:
	# Remove any unnecessary bits from virtual address
	li t0, 0x07FFFFFF000
	and a0, a0, t0

	# Remove any unnecessary bits from physical address
	li t0, 0x00FFFFFFFFFFF000
	and a1, a1, t0

	# Get physical address of root page table
	csrr t0, satp
	li t1, 0x00000FFFFFFFFFFF
	and t0, t0, t1 # Remove any unnecessary bits
	li t1, 4096
	mul t0, t0, t1 # Since SATP contains PPN, we need to multiply by the page size to get physical address

	# set n = 2
	li t1, 2

	# jump to recursion
	j _map_virtual_address_to_physical_address_recursion

	# t0 = physical address of page table
	# t1 = n
	_map_virtual_address_to_physical_address_recursion:
		# if n=0, jump to base case
		beqz t1, _map_virtual_address_to_physical_address_base_case

		# Get VA[n] and multiply by PTE_SIZE to PTE
		li t3, 0x1FF
		li t4, 9
		mul t4, t4, t1
		addi t4, t4, 12
		sra t4, a0, t4
		and t2, t3, t4
		li t4, 8
		mul t2, t2, t4
		
		# Add to page table base address
		add t2, t0, t2

		# Check if PTE is valid. If not, kalloc a new one and update page table
		# If yes, get base physical address, decrement n, and recurse
		ld t3, (t2)
		andi t4, t3, 1
		beqz t4, _map_virtual_address_to_physical_address_kalloc_new_page
		j _map_virtual_address_to_physical_address_read_address_and_recurse

		# t2 = physical address of PTE
		_map_virtual_address_to_physical_address_kalloc_new_page:
			# kalloc a page
			push
			call _kalloc_wrapper
			pop

			# create PTE for that page
			push
			mv a0, a2
			li a1, 0b000
			call _convert_physical_address_to_pte
			pop

			# insert into page table at already known address
			sd a2, (t2)
			mv t3, a2 # Not really needed except to fulfill t3 = PTE precondition in next section

			# jump to read PTE and recurse
			j _map_virtual_address_to_physical_address_read_address_and_recurse

		# t2 = physical address of PTE
		# t3 = PTE entry
		_map_virtual_address_to_physical_address_read_address_and_recurse:
			# Read PTE
			push
			mv a0, t3
			call _get_physical_address_from_pte
			pop
			mv t0, a2

			# Decrement n
			addi t1, t1, -1

			# recurse (ie jump to _map_virtual_address...recursion
			j _map_virtual_address_to_physical_address_recursion

	# t0 = physical base address of page table
	_map_virtual_address_to_physical_address_base_case:
		# We are now in n=0, so we need to get VA[0] and multiply by PTE_SIZE
		mv t4, a0
		srai t4, t4, 12
		andi t3, t4, 0x1FF
		li t4, 8
		mul t3, t3, t4

		# Add to page table base address to get PTE physical address
		add t3, t3, t0

		# Since we've already kalloc'd our page, we can create a PTE for the address
		push
		mv a0, a1
		li a1, 0b111
		call _convert_physical_address_to_pte
		pop

		# Set A bit to 1
		li t2, 0x40
		or a2, a2, t2

		# insert PTE into table
		sd a2, (t3)

		# Return
		ret

