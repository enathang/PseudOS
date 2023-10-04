# From kernel/uart.S
# Symbols: %b will print a register value in binary
#          %h will print a register value in hex
#          %s will print a register value in short-binary (8 bits)

# Welcomes
welcome_message: .ascii "Welcome to PseudOS\n\0"
.align 12
supervisor_mode_welcome: .ascii "Welcome to Supervisor Mode \n\0"
user_mode_welcome: .ascii "Welcome to User Mode \n\0"

# Machine info messages
child_hart: .ascii "I am a child hart % s \0"
machine_mode: .ascii "Mode: % \n\0"

# Bootup steps
bootup_output_mode: .ascii "\n===== Checking msource register for current permission mode =====\n\0"
bootup_machine_hardware_info: .ascii "\n===== Checking misa register for hardware info =====\n\0"
bootup_launch_into_supervisor_mode: .ascii "\n===== Launching into supervisor mode =====\n\0"
create_root_page_table: .ascii "\n===== Create root page table =====\n\0"
jump_into_supervisor_mode: .ascii "\n===== Jump into supervisor mode =====\n\0"
supervisor_pte_message: .ascii "\nPage table entry for supervisor mode entry is: \n\0"
supervisor_physical_page_message: .ascii "\nPhysical address for supervisor mode entry is: \n\0"
map_supervisor_virtual_addresses_message: .ascii "\nMapping virtual addresses for supervisor mode \n\0"
jumping_to_elf_entry_message: .ascii "\nJumping to ELF entry at $ \0"

# Paging
free_range_start_message: .ascii "\nStarting to free memory range from %h to %h\n\0"
free_range_message: .ascii "\nFreed memory range of size %h \n\0"

# Unit tests helper strings
begin_unit_test_message: .ascii "\n===== Beginning unit tests/sanity_checks =====\n\0"
test_result_00: .ascii "\nShould print 'Welcome to PseudOS':\n\0"
test_result_10: .ascii "\nShould be 0b00..000: \n\0"
test_result_11: .ascii "\nShould be 0b00..01110:\n\0"
test_result_12: .ascii "\nShould be all 1s:\n\0"
end_unit_test_message: .ascii "\n===== End unit tests =====\n\0"

# Trap error messages go here
# Note: Per _write_uart implementation, $ will print as register literal, % will print ascii value offset from 'A', and & will print as ascii not offset
machine_trap_instruction_misaligned_warning: .ascii "Machine trap: instruction misaligned. Value: %h \n\0"
machine_trap_instruction_access_fault_warning: .ascii "Machine trap: instruction access fault. Value %h \n\0"
machine_trap_handler_illegal_instruction_fault_warning: .ascii "Machine trap: illegal instruction. Register binary is: \n\0"
machine_trap_instruction_page_fault_warning: .ascii "Machine trap: instruction page fault. Page: %h \n\0"
machine_trap_load_access_fault_warning: .ascii "Machine trap: load access fault. Address %h \n\0"
machine_trap_store_amo_access_fault: .ascii "Machine trap: store/amo access fault. Mtval is: %h \n\0"
machine_trap_handler_load_page_fault_warning: .ascii "Machine trap: load page fault. Page is %h \n\0"
machine_trap_handler_store_amo_page_fault_warning: .ascii "Machine trap: store/amo page fault. Mtval value is: %h \n\0"
machine_trap_warning: .ascii "Warning, machine trap. Exception code: %h, mtval: %h \n Consider adding a specific handler for this trap. \n\0"

dump_heap_message: .ascii "\n===== Heap dump =====\n\0"
dump_page_table_message: .ascii "\n===== Page table dump =====\n\0"

supervisor_trap_warning: .ascii "Warning, supervisor trap. Exception code: %h, mtval: %h \n\0"

# PCI
setup_pci_device_unknown_device_warning: .ascii "Detected PCI device with unknown [deviceId][vendorId]: %h, so skipping setting it up \n\0"

# Misc
number_char: .ascii "%\0"
newline: .ascii "\n\0"
debugging_message: .ascii "\nDebugging: \n\0"
hex_map: .ascii "0\01\02\03\04\05\06\07\08\09\0A\0B\0C\0D\0E\0F\0"

