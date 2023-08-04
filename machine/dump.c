#include <stdint.h>
extern uint64_t* _heap_counter;
extern uint64_t* _heap_end;

extern void _write_uart_wrapper(char*);
extern void _write_register_to_uart_literal_wrapper(uint64_t, uint64_t, uint64_t);

void dump_heap() {
	uint64_t* heap_count = _heap_counter;
	_write_uart_wrapper("Heap counter is: \0");
	_write_register_to_uart_literal_wrapper((uint64_t)_heap_counter, 0, 63);
	_write_uart_wrapper("\n\0");
	
	for (uint64_t i=0; i<(uint64_t)heap_count; i++) {
		// since sizeof(uint64_t)=64, *64 is 4096 (1 page)
		uint64_t* heap_page = _heap_end - (i*64);
		_write_uart_wrapper("Heap page \0");
		_write_register_to_uart_literal_wrapper(i, 0, 8);
		_write_uart_wrapper(" at address \0");
		_write_register_to_uart_literal_wrapper((uint64_t)heap_page, 0, 63);
		_write_uart_wrapper(" contains data \0");
		_write_register_to_uart_literal_wrapper((uint64_t)heap_page, 0, 63);
		_write_uart_wrapper("...\n\0");
		//print_heap_page();
	}

	return;
}

void dump_page_table(uint64_t* page_table_base_address, uint8_t depth, uint8_t max_depth) {
	uint64_t pte_size = 64;
	uint64_t page_size = 4096;
	uint64_t num_pte_entries = page_size / pte_size;

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
		_write_register_to_uart_literal_wrapper(i, 0, 8);

		if (rwx_bits == 0) {
			// Recurse down table
			_write_uart_wrapper("\n\0");
			dump_page_table((uint64_t*) address, depth+1, max_depth);
		} else {
			// Output virtual address -> physical address mapping, depth, and urxw permissions
			_write_uart_wrapper("-> Physical address is: \0");
			_write_register_to_uart_literal_wrapper(address, 0, 63);
			_write_uart_wrapper(", rxw bits are: \0");
			_write_register_to_uart_literal_wrapper(rwx_bits, 0, 2);
			_write_uart_wrapper(", u bit is: \0");
			_write_register_to_uart_literal_wrapper(u_bit, 0, 1);
			_write_uart_wrapper("\n\0");
		}
	}

	return;

}

/*
void dump_heap_block(uint64_t* heap_block) {

	for (int i=0; i<64; i++) {

		_write_register_to_uart_literal_wrapper();
	}

	return;
}*/
