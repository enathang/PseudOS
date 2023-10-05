#include <stdint.h>

extern void _write_uart_wrapper(char*);
extern void _write_uart_formatted(char*, uint64_t, uint64_t, uint64_t);
extern void _write_register_to_uart_hex_wrapper(uint64_t);
extern void _write_register_to_uart_binary_wrapper(uint64_t, uint64_t, uint64_t);

void dump_heap(uint64_t* _heap_end) {
	for (uint64_t i=0; i<512; i++) {
		// since sizeof(uint64_t)=8 bytes, *512 is 4096 bytes (1 page)
		// note sizeof(uint64_t) == sizeof(uint64_t*) on 64 bit machine
		uint64_t* heap_page = _heap_end - ((i+1)*512);
		_write_uart_formatted("Heap page at address %h ", (uint64_t)heap_page, *heap_page, 0);
		_write_uart_formatted("contains data %h%h...\n", *heap_page, *(heap_page+1), 0);
	}

	return;
}

void dump_page_table(uint64_t* page_table_base_address, uint8_t depth, uint8_t max_depth) {
	uint64_t pte_size = 64;
	uint64_t page_size = 4096;
	uint64_t num_pte_entries = page_size / pte_size;
	
	if (depth > max_depth) {
		for (uint8_t j = 0; j<depth; j++) {
			_write_uart_wrapper("\t\0");
		}

		_write_uart_wrapper("Exceeded max depth (probably due to loop in page table). \n\0");
		return;
	}
	
	for (uint8_t j = 0; j<depth; j++) {
		_write_uart_wrapper("\t\0");
	}

	_write_uart_formatted("Detected page table of depth %h with base address %h \n\0", (uint64_t)depth, (uint64_t)page_table_base_address, 0);	
		

	for (uint64_t i=0; i<num_pte_entries; i++) {
		uint64_t* pte_address = page_table_base_address + i; // Adds 64 bits *i
		uint64_t pte = *pte_address;

		uint8_t valid_bit = pte & 0b1;
		uint8_t rwx_bits = (pte & 0b1110) >> 1;
		uint8_t u_bit = (pte & 0b10000) >> 4;
		uint64_t address = (pte << 2) & 0xFFFFFFFFFFF000;

		if (valid_bit == 0) continue;	

		// Formatting
		for (uint8_t j = 0; j<depth; j++) {
			_write_uart_wrapper("\t\0");
		}

		if (rwx_bits == 0) {
			_write_register_to_uart_binary_wrapper(i, 0, 8);
			// Recurse down table
			_write_uart_wrapper("\n\0");
			dump_page_table((uint64_t*) address, depth+1, max_depth);
		} else if (depth == max_depth) {
			_write_register_to_uart_binary_wrapper(i, 0, 8);
			// Output virtual address -> physical address mapping, depth, and urxw permissions
			_write_uart_formatted("-> Physical address is: %h, rxw bits are %s, ubit is %s \n\0", address, rwx_bits, u_bit);
		}
	}

	return;

}

void dump_page_table_raw(uint64_t* page_table_base_address, uint8_t depth, uint8_t max_depth) {
	uint64_t pte_size = 64;
	uint64_t page_size = 4096;
	uint64_t num_pte_entries = page_size / pte_size;
	// Formatting
	for (uint8_t j = 0; j<depth; j++) {
		_write_uart_wrapper("\t\0");
	}

	_write_uart_formatted("Dumping raw page table at depth %s, base address %h :\n\0", depth, (uint64_t)page_table_base_address, 0);

	if (depth > max_depth) {
		_write_uart_wrapper("Max depth exceeded, and table address above is part of loop\n\0");
		return;
	}

	for (uint64_t i=0; i<num_pte_entries; i++) {
		uint64_t* pte_address = page_table_base_address + i; // Adds 64 bits *i
		uint64_t pte = *pte_address;

		uint8_t valid_bit = pte & 0b1;
		uint8_t rwx_bits = (pte & 0b1110) >> 1;
		uint8_t u_bit = (pte & 0b10000) >> 4;
		uint64_t address = (pte << 2) & 0xFFFFFFFFFFF000;
		
		// Formatting
		for (uint8_t j = 0; j<depth; j++) {
			_write_uart_wrapper("\t\0");
		}
		
		_write_register_to_uart_binary_wrapper(pte, 0, 63);
		_write_uart_wrapper("\n\0");
	
		if (rwx_bits == 0 && valid_bit == 1) {
			// Recurse down table
			_write_uart_wrapper("\n\0");
			dump_page_table_raw((uint64_t*) address, depth+1, max_depth);
		}
	}

	return;

}

