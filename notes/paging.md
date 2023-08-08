Okay, so paging is complicated enough that I'm breaking it into it's own notes page.

In Sv39, addresses are 
`[ va[2] ][ va[1] ] [ va[0] ][ offset ]`. 
`(9 bits) (9 bits)  (9 bits)  (12 bits)`

Which means a level 0 table
can cover 2^9 (512) pages, which each page size 2^12 (4096). Therefore, level 0 page table can cover 512 page allocations,
or 2mB (0x200000) total memory. 

By extension, level 1 page table can cover 2^9 level-0 page tables, or 0x40000000. Another way of putting this statement is
if two memory addresses are 0x40000000 apart, they necessarily need different level 2 page table entries. Of course, depending
on page alignment two addresses could need different level2 page entries anyway, if they fall on different multiples of 
0x40000000.

Good rule of thumbs:
- Each page will have its own entry in L0 page table, because they are necessarily 4096 bytes apart.
- If two addresses have a different address multiple of 0x200000, they'll have different L1 page table entries
- If two addresses have a different address multiple of 0x40000000, they'll have different L2 page table entries.
- If two addresses have a different address multiple of 0x8000000000, then they can't be covered in Sv39 and we have a problem.

Our kernel memory space currently has size 0x8000000 and QEMU has space 0x80000000, for total space of 0x88000000. Therefore, 
we will need to utilize all three levels of the page table, but our address space should easily fit within the three levels. 


Calling map_virtual_address_to_physical_address from the kernel:
When we first boot the kernel, we kalloc a number of pages for the page table. The bootloader (in machine mode) uses physical addresses,
so we don't need to worry about paging. However, once we enter supervisor mode, everything works through paging. Incidentally, the 
kernel and user space use the same page tables, so the kernel needs to be able to modify its own page table. To do so, the kernel needs
to have the page tables mapped in the page tables. This bootstrapping process can be complex, so we do it in machine mode.

Specifically, when the kernel tries to map an address, we do the following:
- kernel looks up root_page_table address, which has been mapped by machine to itself.
- kernel gets the PTE of the virtual address and checks if valid. If not valid, create it. If valid, go to it.
    - If create it, kalloc new page, and map it
    - The issue (I believe) is as soon as we have a kalloc that requires a new L1 page, we infinitely recurse creating and trying to map it.
    This is due to kalloc's new address being above existing addesses, which means it also requires the new L1 page, so before it can act as
    the new L1 page it also tries to create a new L1 page.

I suppose we could do the following:
- Create special memory section for page tables.
- When kernel needs to, it tries to update the page table
- If kernel gets page fault, machine can check address and see it's within page table boundaries
- the machine then allocates a new page table within page table boundaries and maps it to page table, then returns to kernel
- kernel then retries the mapping and should be successful (or trap with lower level page table, which machine can also handle)
- If page fault is outside page table boundaries, machine handles some other way


Notes:
- Worth keeping in mind that each address addresses a byte (afaik). Therefore, when we say an address space is 4096 bits, it can
address 4096 bytes of data (or 4kB).
- If we wanted to enumerate each page table, so we never had to kalloc a new page table, it would take 1*512*(512^2)=a lot of pages.
