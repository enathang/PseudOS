A process is defined as "an execution stream in the context of a particular process state"
An execution stream -> a sequence of instructions
A process state -> everything that can affect, or be affected by, the process (ie code, registers, call stack, etc.)

Thread -> one execution state, multiple execution streams
Three possible thread states: Running, blocked, ready

Each process is controlled by a process control block, which keeps track of each process

The dispatcher is the part of the kernel that chooses which thread to run. 
It:
- Runs a thread for a while
- Save the state
- Loads another thread
- Runs it

How does the OS guarantee the userspace will give control back to the dispatcher?
The OS will set up CLINT and configure a regular timer to interrupt and bring control back to the kernel.

Process creation:
- `fork()`
- `exec()`
- `waitpid()`

https://www.gotothings.com/unix/system-kernel.jpg

https://www.brendangregg.com/Perf/linuxperftools.png
