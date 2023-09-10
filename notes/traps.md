Notes on traps:

A trap is a transfer of control (intentionally or accidentally) from the current privilidge level to a higher one. There are three types of traps:
- System calls `ecall`
- Exceptions, or the current privilidge level does something illegal (accessing restricted memory) or just plain weird
- Interrupts, where something outside asks the kernel to take over to handle some event
    - An example is a timer interrupt, telling the kernel to take over and check to see which process to run next

Similar to switching between processes, when a trap occurs the kernel saves the state of the running process before jumping to the code to handle
the trap.

What is covered by the RISC-V hardware during a trap:
- Disable interrupts by clearing SIE (so we don't get interrupted while handling an interrupt and infinitely loop)
- save pc in sepc
- save the current mode in sepc
- set scause to the trap's cause
- set mode to supervisor
- copy stvec to pc
- start executing at new pc
(note: if sie is already disabled and it's an interrupt, skip these steps)

What is NOT covered by the hardware (and therefore should by the kernel):
- switching to the kernel page table (because the kernel may not be using a page table)
- switching to kernel stack
- saving register values
