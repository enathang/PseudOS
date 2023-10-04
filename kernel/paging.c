#include <stdint.h>

uint64_t PAGE_SIZE = 512;
extern void _write_uart_formatted(char*, uint64_t, uint64_t, uint64_t);
extern uint64_t* _free_list_head;

void kfree(uint64_t* addr, uint64_t* free_list_head) {	
	// Set all bytes in free page to '0xF5EEF5EEF5EEF5EE', which is the closest in hex I could come with to 'FREE'
	for (uint64_t offset=0;offset<PAGE_SIZE; offset++) {
		uint64_t* page_byte_pointer = addr + offset;
		(*page_byte_pointer) = 0xF5EEF5EEF5EEF5EE;
	}

	// Prepend free page to free list
	//_write_uart_formatted("Head is %h, next is %h\n", (uint64_t)free_list_head, *free_list_head, 0);
	//_write_uart_formatted("Addr pointer is %h, addr_value is %h\n" , (uint64_t)addr, *addr, 0);
	*addr = *free_list_head;
	//_write_uart_formatted("Addr pointer is %h, addr_value is %h\n" , (uint64_t)addr, *addr, 0);
	*free_list_head = (uint64_t) addr;
	//_write_uart_formatted("Head is %h, next is %h\n\n", (uint64_t)free_list_head, *free_list_head, 0);

}

uint64_t kfreerange(uint64_t* free_list_head, uint64_t* start_addr, uint64_t* end_addr) {
	if (start_addr >= end_addr) {
		_write_uart_formatted("Start address %h is greater than end address %h\n", (uint64_t)start_addr, (uint64_t)end_addr, 0);
		return 0;
	} else if ((uint64_t)start_addr % 0x1000 != 0) {
		_write_uart_formatted("Start address %h is not a multiple of page_size (0x1000)\n", (uint64_t)start_addr, 0, 0);
		return 0;
	}

	_write_uart_formatted("Freeing memory range from %h to %h\n", (uint64_t)start_addr, (uint64_t)end_addr, 0);
	for (uint64_t* addr = start_addr; addr < end_addr; addr+= 512) {
		//_write_uart_formatted("Freeing page at address %h, free_list_root is %h \n", (uint64_t)addr, *free_list_head, 0);
		if (*free_list_head > 0) {
		//	_write_uart_formatted("Next in free list is %h\n", *(uint64_t*)*free_list_head, 0, 0);
		}
		kfree(addr, free_list_head);
	}

	return (uint64_t)(end_addr - start_addr)*8;
}

uint64_t* kalloc() {
	uint64_t* first_free_page = _free_list_head;
	uint64_t* second_free_page = (uint64_t*) *first_free_page;
	_free_list_head = second_free_page;

	return first_free_page;
}

void map_virtual_address_to_pysical_address(uint64_t* va, uint64_t* pa) {

}

uint64_t convert_physical_address_to_pte(uint64_t addr, uint64_t rxw_bits) {
	uint64_t valid_bit = 1;

	addr = addr & 0x00FFFFFFFFFFF000;
	addr = addr >> 2;
	addr = addr | (rxw_bits << 1);
	addr = addr | valid_bit;

	return addr;
}

uint64_t convert_pte_to_physical_address(uint64_t pte) {
	pte = pte & 0x003FFFFFFFFFFC00;
	pte = pte << 2;

	return pte;
}

