---
title: "Writing a RiscV linter"
date: 20223-05-11T13:40:44-07:00
draft: true
---


Below are some notes/thoughts on writing a RiscV assembly linter:

## Terms:
- clobber: a technical term meaning to overwrite a register value with another value, presumably unknowingly
- volating/non-volatile registers: my personal term referring to whether registers can be considered 'safe from modification' (s0 is safe) or not (t0, a0, etc.)
Volatile means unsafe from modification, and non-volatile means safe, as defined in the RiscV ABI.

As pseudOS has evolved, I have learned (more of) the RiscV ABI. Some of the existing code does not reflect that ABI, specifically register
usage, which can occasionally cause bugs when integrating with C code (because LLVM produces ABI-compliant assembly). In addition, there have been
a few bugs occur because I forgot to add a jump or return statement to a section of assembly. The assembly will automatically step
into the next instruction in memory, causing some unexpected behaviors. 

Of course, a more experienced assembly programmer would not run into these issues. But we probably shouldn't rely on the mantra of "just write
it right the first time" and anyway, I have to migrate the existing codebase to be ABI compliant. Therefore, it makes sense to explore using a
RiscV linter to identify existing issues and pre-emptively identify new ones.

Per Wikipedia `Lint is the computer science term for a static code analysis tool used to flag programming errors, bugs, 
stylistic errors and suspicious constructs.` Of the two use cases mentioned above, clobbering a saved register and not restoring it before
function return (as defined by the ABI) would be a `programming error` while not ending all code blocks with a jump or ret would fall under `stylistic errors`.
(it's a stylistic error simply because I find it personally useful, not because it's defined as "best practice" or anything).

## What is the RiscV ABI?
https://riscv.org/wp-content/uploads/2015/01/riscv-calling.pdf

## Existing tools:
As far as my preliminary searching goes, there is not an existing RiscV linter (or really any assembly linter) publicly available. Probably due to 1) few people write in assembly
2) the people that do write assembly know how to write good assembly 3) if assembly linter tools exist they're probably hidden in search results because assembly is a niche topic (see 1).

In addition, because an AST generates assembly and not the other way around, there is no parser for RiscV assembly. There's not even a Treesitter grammar for assembly for syntax highlighting. Wild. 

There is a basic parser written by Austin Henley in https://austinhenley.com/blog/parsingriscv.html. It's pretty basic, only keeping track of a state and peeking ahead one token for context. Still, it's dangerous to go alone.

I know there are tools like YACC (yet another compiler-compiler), which can generate parsers/compilers from language specifications. If there's YACC, is there YALC (Yet another linter compiler)?
It looks like Coala (https://github.com/coala/coala) exists as a language-agnostic linter framework. However, it does not seem to be actively maintained and documentation to onboard new languages is sparse. 

## Intuition for linter

Note, the linter lints based on a "high-level programming language" model. There's a concept of `functions`, which are denoted between `call` and `return`
instructions, which are different from the control flow logic, used by jumps and branches. I'm not sure if that's indicative of good abstraction for assembly
or simply that I've been trained in "high-level programming languages" so I'd be interested to see what professional RiscV assembly looks like and if they 
follow a similar abstracted structure. There's no way to explicitly check if a function returns the
value in the right register (a0 or a1) but one could try to lint that based on comment docs in the assembly code. 


## Linter specification

### Use case 1:
Given a set of assembly symbols, check that each symbol has a jump or return statement as the last statement before the next symbol. Bonus would be
to also check that any jump statement with no saved return address should be the last instruction in that control flow block.

Code example:
```
# a0 = number to add
_increment:
    li t0, 1
    add a0, a0, t1

    # Note we forgot to add a ret instruction here

_decrement:
    li t0, -1
    add a0, a0, t1

    ret

_func:
    li a0, 5
    call _increment
    ret # we expect a0=6, but from our code a0=5
```

*The bug:*
Because we forgot to add a return statement to the `_increment` function, the CPU will naively (and technically correctly) step through to the `_decrement` function. When the function returns, `a0` will not have been incremented. 

*How the linter should fix it:*
The linter should throw an error saying `_increment` has no explicit control-flow jump at the end (or perhaps just a warning).

*Linter rule:*
We define a code block as a label followed by one or more instructions before another label. This definition distinguishes from a label used as a text segment, such as `_stack`. We define an explicit control flow jump as one of `[j, jr, ret]`. We do not define `call` or `jalr` as an explicit control flow jump because ending a code block with one of those implies a return to the end of the code block. 

A code label does not exist in the concept/lexicon of assembly. There's assembly and then there's the code style/abstraction layer we put on top of assembly. We define a code label as a label that precedes an assembly instruction. We can describe this abstraction layer with an AST or with parser rules. 



### Use case 2:
Given a set of volatile and non-volatile registers (as defined explicitly by the ABI), check that any non-volatile register is restored before returning
(as defined by `ret`) and check that any volatile register is not used after (potential) modification by a `call`. It is unclear at the moment if this
check can/should be a theoretical check (throw error even if called function does no volatile register modification) or concrete (throw error
only if calling function explicitly modifies volatile register). Considering the linter would probably run at the compile/assemble step (pre-linking), there
would be no way to do a concrete check on un-linked files (such as libraries to code) so a theoretical check might be necesary. It would be interesting to see if
LLVM supports such an ability.

Code example (of theoretical check):
```
_add:
    mv t3, a1
    push
    call _other_function
    pop

    add a0, a0, t3

    ret

_other_function:
    li t3, 4
    add a0, a0, t3

    ret
```
Because push and pop don't cover `t3` we will be using `t3` when it could have been potentially clobbered by `_other_function` (as could/was `a0`, which are both volatile according to the ABI). 
Therefore, the lintershould probably throw something like "Error: use of volatile register after potential modification" or maybe something more friendly. God, I'm creating
the same error messages I abhor and don't bother to understand. Such as Rust's borrow checker errors. Maybe this is evidence that I should take more time
to learn what those other error messages are trying to tell me.


If the code symbol uses a call or jalr instruction, and later uses a temporary register as input to another instruction in that code block, the linter should throw an error. The exception is if the
liter has been told to ignore the register.


### Use case(s) not covered by linter:
```
_add:
    mv t0, a0
    push_onto_stack t0
    mv a0, t0
    call _print_register
    pop_off_stack t0

    ret

.macro push_onto_stack reg
li t0, 8
add sp, sp, t0
sd \reg, (sp)
.endm

...
```

Here is a somewhat insidious bug I've run into multiple times during OS development. Because the macro abstracts away the fact that t0 gets clobbered
between the `push_onto_stack` and `pop_off_stack` the `_print_register` call will always print 0 despite any initial value of `t0`. There's no easy way
to lint this, because the macro is substituted during pre-processing and we can't really make the same general claims to macro usage as we can to
call/ret. The solution here would probably be to create a new macro

```
.macro call_func func_name arg0
.endm
```
that would prevent any t0 from being modified between push and pop.


Annotations could abstract the linting somewhat from my specific implementation.

Example code annotation:
```
.macro push 
# Linter :- t0, t1, t2, t3, ra, a0, a1
...
.endm

.macro push_ra
# Linter :- ra
...
.endm

.macro pop_ra
# Linter :+ ra
...
.endm
```


## Building the linter
Ideally, we would like to use an AST traversal or a complex parser (such as X) to build a robust linter. That way, we could easily define new rules based on a common interface. Such a project shouldn't be _hard_, especially with some of the existing parser tools, but sometimes it's better to have a tool that works for your specific use case than a semi-finished, unmaintained tool that nobody will use anyway. So, let's hack someething together to see what we're dealing with first and can always abstract things later.

So, we define a few key terms:
- Code block, or a label followed by a set of instructions
- Each code block maintains a list of variables that are 1) written to and 2) read from. To do this, we need to define a list of instructions and which arguments are r/w arguments. 
- Every time a call instruction is used, any temporary variables used after it will be flagged. Argument variables besides a0 and a1 will also be flagged. Note a0 and a1 can still contribute to bugs, and there's nothing we can really do about it because we don't have a lot of information on whether we're expecting return values or not. We could add annotations to our linter to explicitly define such information, but then there's enough friction that the annotations would outweign any time saved in debugging. 
- Any saved registers not restored afterwards are also flagged. 

We can model the state of the CPU with a list of registers, where possible values are SAFE, UNSAFE, and STACK-SAVED (IGNORED). If a unsafe variable is read from, it throws an error because we cannot guarantee the value of the unsafe variable. However, if an unsafe variable is written to, and we have not previously thrown an unsafe error, then the register is now considered safe again. If a variable is stack safe, we ignore any calls/potential modifications to it until it becomes un-stack safe again, at which point it's safe but can become unsafe.

RiscV nicely partitions its instruction set into categories, so we implement a subset of the categories in our linter. 
RiscV OpCodes: https://github.com/michaeljclark/riscv-meta/blob/master/opcodes

Algorithm:
In each code block, set the volatile registers to unsafe and the non-volatile registers to safe. (a0-a6 are considered safe even though they're volatile because they're used to pass arguments).
For each line:
    Parse the instruction
    if regular instruction, 
        check the read registers are SAFE (in the case of li it's safe because no registers are unsafe)
            if UNSAFE, throw error 
        update the written register to SAFE
    if call instruction,
        set all volatile registers back to unsafe
    if jump instruction
        simply continue parsing (but don't throw error for new symbol)
    if save-to-stack instruction
        update register to stack-saved
    if get-from-stack instruction
        update register to safe
    if label (non-instruction)
        throw error about missing explicit control flow statement

To circumvent the limitations of the parser, we can maintain our own state and update accordingly. This allows us to expand the context of our grammar without expanding the parser itself.


Stretch: add checks for returning s0-s11 to original values. 

https://five-embeddev.com/toolchain/2021/09/10/machine-readable-spec/

## Is any of this necessary?
By now, you should understand we are enforcing a set of style contraints on the RISC-V assembly to create a layer of abstraction. This layer basically creates the explicit enforcement of a `call stack` in the assembly. The question remains: why bother? If you're enforcing most or all of the requirements of a higher level programming language like C (amusingly in this scenario C is considered to be "high level"), why not just use C?

I have no real response to that. Especially considering, barring corner cases, the C compiler will optimize the assembly to be more efficient than anything I would write. Perhaps certain programs are more ergonimic to write in assembly (OS bootloader comes to mind) and need to be verified that they still comply with the RISC-V ABI. Still, sometimes you have to journey up a mountain before you can say "eh, it was better in the photos " ;)


## Glossary of contextual questions that arose during this project
### Do assembly labels need to be uniquely named?
Yes. Each need to be uniquely named within the global scope of the assembler/linker (linker may depend on if symbols are statically or dynamically linked). One way to circumvent this is a context
stack (https://www.nasm.us/xdoc/2.15.05/html/nasmdoc4.html#section-4.7) but this solution simply offers a higher level way of specifying names that will be switched to unique names in compilation/assembly.

Put another way, the requirement still exists, but context stacks allow us to push it down the abstraction layer stack to the point where we don't care about it, as we do with most other things such as labels allow us to do with physical addresses.

### What does 'good' RiscV assembly look like?

