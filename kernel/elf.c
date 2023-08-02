// #DEFINE ELF_MAGIC_NUMBER 0x464C457F // 0x7FELF in little endian

#import <stdint.h>

struct elf_header {
	uint32_t magic_number;
	uint8_t ei_class;
	uint8_t ei_data;
	uint8_t ei_version;
	uint8_t ei_osabi;
	uint8_t ei_osabiversion;
	uint32_t ei_pad; // TODO: should be 7?
	uint16_t ei_pad2;
	uint8_t ei_pad3;

	uint16_t e_type;
	uint16_t e_machine;
	uint32_t e_version;
	uint64_t e_entry;
	uint64_t e_phoff;
	uint64_t e_shoff;
	uint32_t e_flags;
	uint16_t e_ehsize;
	uint16_t e_phentsize;
	uint16_t e_phnum;
	uint16_t e_shentsize;
	uint16_t e_shnum;
	uint16_t e_shstrndx;
};

struct program_header {
	uint32_t p_type;
	uint32_t p_flags;
	uint64_t p_offset;
	uint64_t p_vaddr;
	uint64_t p_paddr;
	uint64_t p_filesz;
	uint64_t p_memsz;
	uint64_t p_align;
};


extern void _write_uart(char*);

extern uint64_t _kalloc();
extern void _map_virtual_address_to_physical_address(uint64_t, uint64_t);

extern void _write_register_to_uart_literal(uint64_t, uint64_t, uint64_t);

uint64_t parse_elf(uint64_t* file_header) {
	struct elf_header eh = *(struct elf_header*)file_header;
	//_write_uart("\nE_magic_number: \0");
	//_write_register_to_uart_literal(eh.magic_number, 0, 63);
	//_write_uart("\nE_phnum: \0");
	//_write_register_to_uart_literal(eh.e_phnum, 0, 63);

	for (int i=0; i<eh.e_phnum; i++) {
		struct program_header ph = *(struct program_header*)(file_header + eh.e_phoff + (i * eh.e_phentsize));
		// NOTE: calling these print functions will mess with the value :(
		_write_uart("\nph.ptype: \0");
		_write_register_to_uart_literal(ph.p_type, 0, 63);
		
		if (ph.p_type == 1) { // should load into memory
			uint64_t size_to_allocate = ph.p_memsz;
			uint64_t virtual_address = ph.p_vaddr;
			uint64_t flags = ph.p_flags;

			_write_uart("\nSize to allocate: \0");
			_write_register_to_uart_literal(size_to_allocate, 0, 63);
			
			// Only support 4kB pages right now
			if (size_to_allocate != 4096) {
				_write_uart("\nUh-oh. Trying to allocate a non-4096 size page\0");
				return 0;
			}
			
			uint64_t physical_address = _kalloc();
			// Ignore rwx flags for now
			_map_virtual_address_to_physical_address(virtual_address, physical_address);
		} else {
			_write_uart("\nCan't load into memory because of ph.ptype: \0");
			_write_register_to_uart_literal(ph.p_type, 0, 63);
		}
	}

	uint64_t entry = eh.e_entry;
	return entry;
}
