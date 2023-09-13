// Take in address to ELF file
#include <_types/_uint64_t.h>
#include "process.h"

void exec(uint64_t* file_header) {
	struct process proc;
	uint64_t* proc_root_page_table = kalloc();

	proc.root_page_table = proc_root_page_table;

}
