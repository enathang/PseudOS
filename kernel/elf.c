#import <stdint.h>
#import "paging.h"

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


extern void _write_uart_wrapper(char*);
extern void _write_register_to_uart_binary_wrapper(uint64_t, uint64_t, uint64_t);
extern void _write_uart_formatted(char*, uint64_t, uint64_t, uint64_t);

extern void _map_virtual_address_to_physical_address(uint64_t, uint64_t, uint64_t);


uint64_t parse_elf(uint64_t* file_header) {
	_write_uart_formatted("Beginning parse_elf with elf file at address %h...\n\0", (uint64_t) file_header, 0, 0);
	struct elf_header eh = *(struct elf_header*)file_header;
	
	if (eh.magic_number != ELF_MAGIC_NUMBER) {
		_write_uart_formatted("Attempted to load ELF binary, but magic number (%h) was not correct. Skipping it.\n\0", eh.magic_number, 0, 0);
	}

	_write_uart_formatted("Phnum: %h, phentsize: %h \n\0", eh.e_phnum, eh.e_phentsize, 0);

	// TODO: Create new page table for the process
	for (int i=0; i<eh.e_phnum; i++) {
		// Note: In C, pointer arithmetic uses the pointer data type size implicitly. So, (uint32_t *)+1 will move the pointer
		// sizeof(uint32_t) bytes over. We receive the program header offset and size as bytes. Therefore, we cast to uint8_t
		// temporarily to easily define how many bytes we want to jump over, jump, and then re-cast back to appropriate pointer
		struct program_header ph = *(struct program_header*)(
			(uint8_t*)file_header
			+ (eh.e_phoff/sizeof(uint8_t))
			+ (i * (eh.e_phentsize/sizeof(uint8_t)))
		);
		_write_uart_formatted("\tph.ptype: %h \n\0", ph.p_type, 0, 0);
		
		if (ph.p_type == 1) { // should load into memory
			_write_uart_wrapper("\t\tShould load into memory\n");
			uint64_t size_to_allocate = ph.p_memsz;
			// May need to map to page size
			uint64_t virtual_address = ph.p_vaddr;
			uint64_t flags = ph.p_flags;
			_write_uart_formatted("\t\tSize to allocate: %h\n", size_to_allocate, 0, 0);	
			_write_uart_wrapper("\t\tAllocating memory... \n");
			uint64_t* physical_address = kalloc();
			_write_uart_formatted("\t\tVirtual address: %h, physical address: %h \n\0", virtual_address, (uint64_t)physical_address, 0);
			
			// Map to user page (ignore rxw flags specified in elf section for now)
			// TODO: add mapping to process rather than kernel root table
			_map_virtual_address_to_physical_address(virtual_address, (uint64_t)physical_address, 0b1111);
		} else {
			_write_uart_formatted("\t\tProgram header type (%h) isn't of type 'Loadable segment', so skipping loading it. \n", ph.p_type, 0, 0);
		}
	}

	_write_uart_wrapper("Finished parse_elf, returning...\n\n\0");
	uint64_t entry = eh.e_entry;
	return entry;
}
