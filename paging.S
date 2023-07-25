
# kalloc
# Inputs: none
# return: a2, the physical address of new 4kB page
_kalloc:
	# Increment heap counter
	la t1, _heap_counter
	lb t0, (t1)

	li t2, 1
	add t0, t0, t2
	sb t0, (t1)

	# get address of new page based on heap counter
	la t1, _heap_end
	li t2, 4096
	mul t0, t0, t2

	# return address
	sub a2, t1, t0
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
			call _kalloc
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

		# insert PTE into table
		sd a2, (t3)

		# Return
		ret


# a0 = virtual address
# a1 = physical address
# a2 = rwx bits
_map_virtual_to_physical_page:
	mv a3, a1
	push
	la a0, supervisor_physical_page_message
	call _write_uart
	pop
	debug_reg a1

	# Remove any bits before and after the virtual address
	li t0, 0x07FFFFFF000
	and a0, a0, t0
	# Remove any bits before and after the physical address
	li t0, 0x00FFFFFFFFFFF000
	and a1, a1, t0
	# get physical address of root page table
	csrr t0, satp
	# zero out unneeded parts of the SATP
	li t1, 0x00000FFFFFFFFFFF
	and t0, t0, t1
	# Because SATP contains the PPN and not address, we have to multiply times page size
	li t1, 4096
	mul t0, t0, t1

	# Get va[2]
	mv t1, a0
	srai t1, t1, 30 # VA[2] starts at 30
	li t2, 8 # PTE_SIZE
	mul t1, t1, t2
	add t0, t0, t1 # t0 now contains physical address of PTE in level 2
	
	# Check if PTE is valid. If no, create a new one and update the page table
	# if yes, go to next level page table	
	ld t1, (t0)
	andi t2, t1, 1	
	beqz t2, _create_level_1_page_table
	j _go_to_level_1_page_table

	_create_level_1_page_table:
		# allocate new page table
		push
		call _kalloc
		pop

		# create new PTE for the new page table
		push
		mv a0, a2 # kalloc returns the new address in a2, which we move to a0 as input to make into PTE
		li a1, 0b000 # r, w, x = 0 (which signifies non-leaf node)
		call _convert_physical_address_to_pte
		pop

		# load a1 into root_page_table (PTE address should be still stored in t0 from above)
		sd a2, (t0)
		mv t1, a2
		j _go_to_level_1_page_table
		# Post-condition: t1 contains the PTE of level 2 for level 1 table

	_go_to_level_1_page_table:
		# Read PTE and get new physical page 
		push
		mv a0, t1
		call _get_physical_address_from_pte
		pop
	
		# Read VA[1] from virtual address
		mv t3, a0
		srai t0, t0, 21
		li t1, 0x1FF
		and t0, t0, t1

		# multiply by PTE size to get offset of pte1
		li t1, 8 # PTE_SIZE
		mul t0, t0, t1
		add t0, a2, t0

		# Check if PTE is valid. If no, create a new one and update the page table
		# if yes, go to next level page table
		ld t1, (t0)
		andi t2, t1, 1
		beqz t2, _create_level_0_page_table
		j _go_to_level_0_page_table_and_insert

	_create_level_0_page_table:
		# allocate new page table
		push
		call _kalloc
		pop	

		# create new PTE for the new page table
		push
		mv a0, a2 # kalloc returns the new address in a2, which we move to a0 as input to make into PTE
		li a1, 0b000 # r, w, x = 1 (which signifies leaf node)
		call _convert_physical_address_to_pte
		pop

		# load a1 into root_page_table (PTE address should be still stored in t0 from above)
		sd a2, (t0)
		mv t1, a2
		j _go_to_level_0_page_table_and_insert
		# Post-condition: t1 contains the PTE of level 2 for level 1 table
		
	
	_go_to_level_0_page_table_and_insert:
		# Calculate level 0 PTE physical address
		push
		mv a0, t1
		call _get_physical_address_from_pte
		pop

		# Read VA[0] from virtual address
		mv t3, a0
		srai t0, t0, 12
		li t1, 0x1FF
		and t0, t0, t1

		# multiply by PTE size to get offset of pte1
		li t1, 8 # PTE_SIZE
		mul t0, t0, t1
		add t0, a2, t0 # t0 is address of PTE in level 0	

		# Finally, we can insert new PTE for actual physical page we wanted to map
		push
		mv a0, a3
		li a1, 0b111
		call _convert_physical_address_to_pte
		pop

		# Print out PTE of supervisor entry
		push
		la a0, supervisor_pte_message
		call _write_uart
		pop
		debug_reg a2
		
		sd a2, (t0)

		ret
	

/* REFERENCE:
_map_virtual_address_to_physical_address:
	# Remove any unnecessary bits from virtual address

	# Remove any unnecessary bits from physical address

	# Get physical address of root page table

	# set n = 2

	# jump to recursion

	_map_virtual_address_to_physical_address_recursion:
		# if n=0, jump to base case

		# Get VA[n] and multiply by PTE_SIZE to PTE
		
		# Add to page table base address

		# Check if PTE is valid. If not, kalloc a new one and update page table
		# If yes, get base physical address, decrement n, and recurse

		_map_virtual_address_to_physical_address_kalloc_new_page:
			# kalloc a page

			# create PTE for that page

			# insert into page table at already known address

			# jump to read PTE and recurse

		_map_virtual_address_to_physical_address_read_address_and_recurse:
			# Read PTE

			# Decrement n

			# recurse (ie jump to _map_virtual_address...recursion

	_map_virtual_address_to_physical_address_base_case:
		# We are now in n=0, so we need to get VA[0] and multiply by PTE

		# Add to page table base address to get PTE physical address

		# Since we've already kalloc'd our page, we can create a PTE for the address

		# insert PTE into table

		# Return

*/


