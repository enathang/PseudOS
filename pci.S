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
		ld t4, (t2)

		# If device is present, set it up
		#push
		mv a0, t4
		mv a1, t4
		li t4, 0xFFFF
		and a1, a1, t4
		bne t4, a1, _list_pci_ecam_iter_setup_device
		j _list_pci_ecam_iter_increment
		
		_list_pci_ecam_iter_setup_device:
			mv a1, a0
			mv a0, t2
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

# a0 = address of PCI entry
# a1 = contains [deviceId][vendorId]
_setup_pci_device:	
	# QEMU PCI bridge
	li t1, 0x81B36
	# beq a1, t1, _setup_qemu_pci_bridge

	# QEMU VGA
	li t1, 0x11111234
	beq a1, t1, _setup_qemu_vga

	# Otherwise it's an unknown device, so we print out a warning and skip it
	push
	la a0, setup_pci_device_unknown_device_warning
	call _write_uart
	pop

	ret


_setup_qemu_pci_bridge:
	wfi

