As our OS becomes more complicated, we start to lose visual and familiar sense of the memory layout. Here, we make it explicit as best we can:

QEMU expects a kernel as a ELF binary with entrypoint at position 0x80000000. We allocate 128Mb (0x800000) of space at that position for ram.

Diagram so far:

+------------+ 0x0
| Qemu stuff |
+------------+ 0x80000000
| Our RAM    |
+------------+ 0x88000000

For the Qemu space, the memory is mapped to various Qemu things, such as UART (0x10000000), PCI ECAM (0x30000000), etc.
The full breakdown is available in the source code at (https://github.com/qemu/qemu/blob/master/hw/riscv/virt.c)

Our RAM is where we put our kernel, etc. The memory layout of our kernel is defined in kernel.lds, which manages how the kernel ELF file
is built (which sections go where). It looks something like this:

+-------------+ 0x80000000 (_start)
| .text       |
+-------------+
| .rodata     |
+-------------+
| .data(stack)| (_stack)
+-------------+
| .bss        |
+-------------+
|             |
|   free      |
|             |
+-------------+ 0x87FFFF00 (_heap_end)
| heap counter|
+-------------+ 0x88000000 (_memory_end)

Notably, the heap should expand towards earlier memory addresses as kalloc() is called. The stack should expand towards later memory addresses.
This is the opposite of usual, but not super-uncommon.

Question: does the stack live above .bss or in a separate data segment below it?
 - Based on objdump, looks like stack is put after all other sections

 Now, everything we've noted so far is using physical addresses. However, the supervisor/kernel (just realised hyper-visor and super-visor 
 have semantic hierarchical names. wild.) uses virtual addresses. Which is fine until we try to kalloc and map_virtual_address_to_physical_address
 in the kernel, which gets borked because kalloc (I think, need to check) returns a virtual address, so mapping becomes user_virtual_address->kernel_virtual
 address. Which throws a page fault because there is no kernel_virtual_address -> physical_address mapping in the page table.

 Here's a diagram of the initial virtual->physical page mapping in PseudOS:

 +------------+
 |            |
 +------------+
 |     ...    |
 +------------+
 |  kalloc(1) |
 +------------+
 |  kalloc(0) |
 +------------+
 |heap counter|
 +------------+

Currently, we allocate a page_table_root near the top of the address space, but dynamically create new pages with kalloc. The downside of this approach is we map
the new page into existing page table entry, but because the page size is 4kB and our PTE covers exactly 4kB of addresses, each new page requires a new PTE in 
the lowest page table (which was dynamically allocated). If we update the page tables to map all three page tables to themselves, then we can allocate new pages in
the kernel and have a 4kb*1kb (each PTE covers 4kB and we have 1kB of PTES per page) worth address range.

To accomplish this goal, we need to allocate the level 1 and level 0 page tables, and have the level 1 and level 0 page tables point to themselves. We can 
use the following algorithm:
- Page table level 2 is already allocated
- kalloc page table 0. 
- kalloc page table 1.
- Write page table 0 and 1 into 0
- Write page table 1 into page table 1 and 2
- map page 2 to itself
That should allow the kernel to always map new kallocs to virtual memory, since the kernel can now access each level of the page table.

Basically,
page table 2 should point to page table 1
page table 1 should point to page table 0
page table 0 should point to all page table 0, page table 1, page table 2
