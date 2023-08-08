# Notes:

## Instructions
`la t0, addr` load absolute address from addr into register t0. Addr can be defined in .text or .data section, which is the loaded into memory
`li t0, 1` load intermediate value `1` into t0. I presume it's a pseudo-op that adds 1 and r0, but haven't checked

la vs li vs lw vs lb: First, note the load keyword always refers to putting a value into a register (usually from memory) and store refers to 
writing a value into memory from a register. La refers to load address (of symbol), which puts the address of a symbol into register. lw refers to
load value of symbol.

A byte is always 8bits, whereas a word is the smallest unit that can be addressed in memory. A good intuition is a word is the size of a register
in the architecture, as a register will hold memory addresses for computation. 

## ABI
RISC-V defines a set of names to each of the 32 integer registers through the ABI. Each name corresponds to the intended function of the
register, such as t0,t1 being temporary registers, a0,a1... being function argument registers, s0 are (s)aved registers between function calls.
And zero is the name of x0, the zero register. 

## Misc observations
If the assembly section doesn't have a `ret` instr at the end, it will automatically move onto the next section. This behavior makes sense
but can lead to amusing/annoying bugs where the order of your code sections causes bugs.

One can call a "function" (symbol address) with either `j` or `call`. Not sure the nuances of each, but know using `call` twice in a row can
cause the return pointer address (ra register) to be overwritten and get lost in the program. So temporary storing of the return address
may be necessary in those situations

One important aspect of the ABI (Application Binary Interface) is the contract or guarantees between the caller and callee wrt register values. Each of RV32's
32 general purpose registers are not, in fact, general purpose, but have designated purposes. For example, x0 (ABI name is `zero`) is always zero, x2 (`sp`) 
always points to the stack pointer, x10,x111 (`a0`,`a1`) is used for arguments to function calls, etc. The ABI defines whether a register can be overwritten or not
by the callee function. Any register that can be overwritten needs to be saved by the caller on the stack before invoking the callee. Crucually the ra or return
address register needs to be stored, or else it will be overwritten by a two-level function call (which updates `ra` twice, overwriting and therefore losing the
first value. 

Not sure why I can invoke call as a instruction but no risc v documentation mentions it. Maybe it's an assembly alias for jal? Would be worth checking .o file
to see what it's assembled to. -> According to https://itnext.io/risc-v-instruction-set-cheatsheet-70961b4bbe8 `call offset` = `jalr ra, ra, offset` and `ret`
= `jalr zero, 0(ra)`

Similarly, I can't tell if branch links a register or not. If not, it seems annoying to return from the branching call. Perhaps there's an easy way to jal
conditionally? Worth investigating nested labels. -> branching does not link register. 

General rules of calling conventions with larger assembly codebases: We're getting to the point where functions are long/complex enough that it's difficult
to store in one's head all possible CFG executions and check that no register assumptions are violated. Therefore, I propose the following rules of thumb
to help reduce checks needed. 
 - Functions can accept parameters via a0, a1, and will always return a value by a2
 - Therefore, a0, a1 values should not be modified inside a function except for preprocessing (ie zero-ing out non-needed bits) for the whole function
 - All manipulations should be done inside temporary registers. 

I'm going to have to re-write push/pop or calling conventions because I just realized that it won't work as currently implemented. Specifically,
sometimes I use `push; li t0, 1, call X; pop` which will cause afaik multiple calls to `li t0, 1` and `call X`. Actually, nm that should be fine. As
long as pop happens right after call, because call links the ra with the next instruction.


Linking assembly and C code together:
Compile C -> `clang program.c -o program`  jk because we have to compile it for riscv it's `riscv64-unknown-elf-gcc`

In assembly, we `.extern c_main` and then jump to it
`riscv64-unknown-elf-gcc -c boot.S -o boot.o                               
riscv64-unknown-elf-gcc -c main.c -o main.o                                                           
riscv64-unknown-elf-ld boot.o main.o -T kernel.lds -o kernel.elf                                                              
qemu-system-riscv64 -machine virt -cpu rv64 -smp 4 -m 128M  -serial mon:stdio -bios none -kernel kernel.elf -device VGA`

To view symbol table of object:
`riscv64-unknown-elf-objdump boot.o --syms`

To compile main.c with symbols, remember to use `-mcmodel=medany`

Notes on ABI: Per the useful document https://inst.eecs.berkeley.edu/~cs61c/resources/RISCV_Calling_Convention.pdf RISCV has calling conventions that differ
with what I've used so far in this code. As pointed out in the document, this is fine until it's not, and it usually becomes an issue as soon as you have higher-level code that you compile to assembly that mixes with assembly code. I should be alright as long as I make sure to convert between my calling conventions and the RISCV calling conventions at the boundary of pure-assembly and compiled assembly (famous last words). 

Well, I refactored the kernel into a few new files and am getting all sorts of access errors now :/ best guess atm is the imports are importing the data to the wrong part section(segment?) of the boot.S file. I'll compare against the last git commit to try and triangulate changes causing these issues.

## Todo
- Investigate POSIX iterface
- Add unit testing infrastructure to OS where it will fail if a unit test fails
- Page table unit tests
- Allocate page tables near malloc
- Function sorta works in machine mode but page faults in supervisor mode
- (before or after) move to user-mode

- Re-read RISCV ABI and calling conventions, and align code with that

- Get c_main working in user mode, with traps to suervisor mode for system calls such as print
- Inspect output ELF file to learn the different data segment parts
- Get mandelbrot set or doom or keyboard working on kernel

 - Figure out how to define constants as macros to improve code readability (ie PTE_SIZE rather than 8)

## Done Todo
- Write dump heap and dump page table functions to trigger on page fault
- Figure how to kalloc and add page to page table so supervisor can access it without infinitely recursing, since adding to page table calls kalloc
    - Can I just add it during kalloc and because the page should already exist per mapping() call in machine, everything should be fine(ish)?
- Get fibonacci unit test working
    - Now works; issue was my OS moved stack in opposite direction to gcc. So when I put stuff on the stack, the invoked C code, the stack would expand
    in the other direction and overwrite local variables. Thought of it during my nap (idling on my previously written comment that my stack direction
    was not the usual direction) and then confirmed by examining the assembly of main.C.
- Write notes on memory layout and which directions stack/heap are growing right now for clarity/reference
- Figure out why file refactoring is causing jal (relocation truncated to fit) issues
    - Had to do with import statement being in .data section and not .text section, once I moved the statement there were no issues
- Figure out why nested call pop is causing invalid access error
    - Push and pop should use sd/ld instead of sw/lw. Why? Unsure, I guess addresses use double-words? Need to investigate.
- Understand how to switch to supervisor mode using mret
    - I think there was just some setting that wasn't being set yet, such as page physical access permissions or matp.
- Switch root page table creation to kalloc, then in map virtual to physical retrieve root table via satp register, then create new L1 and L0 tables. Then
 add physical address to L0 table, add L0 table to L1, and add L1 table to L2
    - Done
- Check arguments can be passed from assembly to C, from C to assembly, and that values can be returned from assembly to C
    - Yep! Works easier than expected, although weird side-effects occur because I didn't really follow RiscV ABI

## References
- https://michaeljclark.github.io/asm.html
- https://www.sifive.com/blog/all-aboard-part-4-risc-v-code-models
- https://luplab.gitlab.io/rvcodecjs/
- https://www2.eecs.berkeley.edu/Courses/CS61C/ (specifically https://inst.eecs.berkeley.edu/~cs61c/sp21/)
- https://web.eecs.utk.edu/~smarz1/courses/ece356/notes/assembly/
- https://itnext.io/risc-v-instruction-set-cheatsheet-70961b4bbe8
- https://github.com/qemu/qemu/blob/master/hw/riscv/virt.c
- https://wiki.osdev.org/Pci
- https://gist.github.com/iamgreaser/15a0a81cd117d4efd1c47ce598c13c91
- https://www.cs.cornell.edu/courses/cs3410/2019sp/schedule/slides/11-linkload-notes-bw.pdf
