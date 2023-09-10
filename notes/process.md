Notes on process(es):

The OS maintains a large amount of information on each process in order to manage and easily switch between them. Some information includes
- The register context (`ra, sp, s0-s11`)
- A lock (spinlock?)
- Parent process
- PID
- Paging root page
- All open files
- Process status (waiting, ready, dead, etc.)

How the kernel (xv6) starts the first process:
- Run the bootloader in read only memory
- start `_entry` in kernel
- Set up stack for C code
    - Stack pointer
- Prepare to jump to supervisor mode
    - Set mstatus & mepc, disable supervisor paging
    - Start clock to generate timer interrupts
- mret (into supervisor mode)
- initialize several devices/subsystems
- create userinit process
    - re-enters kernel via `exec`
- create new console device file
- start shell on console
