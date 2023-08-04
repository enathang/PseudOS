Virtual address: 0000000000000000000000000000000000000000000000010000000000000000
Physical address: 0000000000000000000000000000000010000111111111111000000000000000Machine trap: load page fault. Mtval value is 0000000000000000000000000000000010000111111111111110000000000000

I've been hitting my head against a wall for 1+ hours, so now time to take a step back and work through it.
Problem I'm seeing:
During machine mode, we map elf_start to itself in memory

During supervisor mode, we retrieve the address of elf_start and pass to elf.c to parse 

During parsing, we retrieve a program header, which has virtual address above. We kalloc a new physical heap, get the physical address, and then try to add the
virtual address -> physical address in page table by calling map_virtual_address_to_physical_address. 

The problem is during the mapping, we have a load page fault with the physical address that we kalloc'd. As far as I understand, we should never be trying to 
access the physical address until we try to run the ELF file. Instead, we should be just creating a new user mode page


Could use unit tests, code reviews, smaller commits, better sticking to standards such as ABI to allow abstraction
