_list_pci_devices:
	push
	li t0, 256
	j _iterate_devices

	_iterate_devices:
		li t1, 32
		li t2, 1
		j _iterate_devices_iter
	
		_iterate_devices_iter:
			mv a0, t0
			mv a1, t1
			li a2, 0
			push
			call _read_pci
			debug_reg a2
			pop

			li t3, 1
			add t2, t2, t3
			j _iterate_devices_iter
	pop
	
	ret

# a0 = bus
# a1 = device
# a2 = offset
_read_pci:
	push
	mv a3, a2
	li a2, 0
	call _build_address

	ld a2, (a2)
	debug_reg a2
	#li t0, 0xcf8
	#sd a2, (t0)
	#li t0, 0xcfc
	#ld a2, (t0)

	pop

	ret

# a0 = bus number
# a1 = device number 
# a2 = function
# a3 = offset
# return address in a2
_build_address:
	li t0, 0x40000000 # PCI base address is 2^31
	slli a0, a0, 16
	slli a1, a1, 11
	slli a2, a2, 8

	# Add all values to create address and return (in a2)
	add a2, a2, t0
	add a2, a2, a0
	add a2, a2, a1
	add a2, a2, a3

	ret

# Iterate through PCI's ECAM and print the first 64 (128?) bits, which should contain the vendorId and deviceId
_list_pci_ecam:
	li t0, 0x30000000
	li t1, 0
	li t3, 128

	_list_pci_ecam_iter:
		# Get first 32 bits of PCI entry
		li t2, 4096
		mul t2, t1, t2
		add t2, t0, t2
		ld t2, (t2)

		# If device is present, set it up
		#push
		mv a0, t2
		mv a1, t2
		li t2, 0xFFFF
		and a1, a1, t2
		bne t2, a1, _list_pci_ecam_iter_setup_device
		j _list_pci_ecam_iter_increment
		
		_list_pci_ecam_iter_setup_device:
			push
			call _setup_pci_device
			pop
			j _list_pci_ecam_iter_increment

		_list_pci_ecam_iter_increment:
			# Increment and check if we should continue of have enumerated all possible devices
			li t2, 1
			add t1, t1, t2
			blt t1, t3, _list_pci_ecam_iter

			ret

# a0 = contains [deviceId][vendorId]
_setup_pci_device:	
	# QEMU PCI bridge
	li t1, 0x81B36
	beq a0, t1, _setup_qemu_pci_bridge

	# QEMU VGA
	li t1, 0x11111234
	beq a0, t1, _setup_qemu_vga

	# Otherwise it's an unknown device, so we print out a warning and skip it
	push
	mv a1, a0
	la a0, setup_pci_device_unknown_device_warning
	call _write_uart
	pop

	ret


_setup_qemu_pci_bridge:
	wfi


_setup_qemu_vga:
	wfi
