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

## Todo
 - Switch root page table creation to kalloc, then in map virtual to physical retrieve root table via satp register, then create new L1 and L0 tables. Then
 add physical address to L0 table, add L0 table to L1, and add L1 table to L2
 - Figure out how to define constants as macros to improve code readability (ie PTE_SIZE rather than 8)
 - Figure out why loading PTE2 entry is causing access fault (I added a print_hello call after the access so once it succeeds hello should print out)

## Done Todo
- Figure out why nested call pop is causing invalid access error
    - Push and pop should use sd/ld instead of sw/lw. Why? Unsure, I guess addresses use double-words? Need to investigate.
- Understand how to switch to supervisor mode using mret
