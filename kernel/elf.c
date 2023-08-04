#import <stdint.h>
uint32_t ELF_MAGIC_NUMBER = 0x464C457F; // 0x7FELF in little endian

struct elf_header {
	uint32_t magic_number;
	uint8_t ei_class;
	uint8_t ei_data;
	uint8_t ei_version;
	uint8_t ei_osabi;
	uint8_t ei_osabiversion;
	// pad is 7bytes long, so we split into 4,2,1 bytes
	char padding[7]; // WHYYYY???
	//uint32_t ei_pad;
	//uint16_t ei_pad2;
	//uint8_t ei_pad3;

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


//extern void _write_uart(char*);
//extern void _write_register_to_uart_literal(uint64_t, uint64_t, uint64_t);

extern void _write_uart_wrapper(char*);
extern void _write_register_to_uart_literal_wrapper(uint64_t, uint64_t, uint64_t);

extern uint64_t _kalloc();
extern void _map_virtual_address_to_physical_address(uint64_t, uint64_t, uint64_t);


uint64_t parse_elf(uint64_t* file_header) {
	_write_uart_wrapper("Beginning parse_elf...\n\0");
	struct elf_header eh = *(struct elf_header*)file_header;
	
	if (eh.magic_number != ELF_MAGIC_NUMBER) {
		_write_uart_wrapper("Attempted to load ELF binary, but magic number was not correct. Skipping it.\n\0");
	}

	_write_uart_wrapper("\nE_phnum: \0");
	_write_register_to_uart_literal_wrapper(eh.e_phnum, 0, 5);
	_write_uart_wrapper("\nE_phentsize: \0");
	_write_register_to_uart_literal_wrapper(eh.e_phentsize, 0, 5);

	for (int i=0; i<eh.e_phnum; i++) {
		// Note: In C, pointer arithmetic uses the pointer data type size implicitly. So, (uint32_t *)+1 will move the pointer
		// sizeof(uint32_t) bytes over. We receive the program header offset and size as bytes. Therefore, we cast to uint8_t
		// temporarily to easily define how many bytes we want to jump over, jump, and then re-cast back to appropriate pointer
		struct program_header ph = *(struct program_header*)(
			(uint8_t*)file_header
			+ (eh.e_phoff/sizeof(uint8_t))
			+ (i * (eh.e_phentsize/sizeof(uint8_t)))
		);
		_write_uart_wrapper("\nph.ptype: \0");
		_write_register_to_uart_literal_wrapper(ph.p_type, 0, 5);
		
		if (ph.p_type == 1) { // should load into memory
			uint64_t size_to_allocate = ph.p_memsz;
			// May need to map to page size
			uint64_t virtual_address = ph.p_vaddr;
			uint64_t flags = ph.p_flags;

			_write_uart_wrapper("\nSize to allocate: \0");
			_write_register_to_uart_literal_wrapper(size_to_allocate, 0, 10);
			
			_write_uart_wrapper("\nAllocating memory \0");
			uint64_t physical_address = _kalloc();
			// Ignore rwx flags for now
			_write_uart_wrapper("\nVirtual address: \0");
			_write_register_to_uart_literal_wrapper(virtual_address, 0, 63);
			_write_uart_wrapper("\nPhysical address: \0");
			_write_register_to_uart_literal_wrapper(physical_address, 0, 63);
			
			// Map to user page
			_map_virtual_address_to_physical_address(virtual_address, physical_address, 0b1111);
		} else {
			_write_uart_wrapper("\nProgram header isn't of type 'Loadable segment', so skipping loading it. Program header type: \0");
			_write_register_to_uart_literal_wrapper(ph.p_type, 0, 63);
		}
	}

	_write_uart_wrapper("Finished parse_elf, returning...\0");
	uint64_t entry = eh.e_entry;
	return entry;
}
