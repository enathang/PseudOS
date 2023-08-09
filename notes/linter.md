Below are some notes/thoughts on writing a RiscV assembly linter:

Terms:
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

Use case 1:
Given a set of assembly symbols, check that each symbol has a jump or return statement as the last statement before the next symbol. Bonus would be
to also check that any jump statement with no saved return address should be the last instruction in that control flow block.

Code example:
```
# a0 = number to add
_increment:
    li t0, 1
    add a0, a0, t1

    # ret # Note ret is commented out because we were debugging something

_decrement:
    li t0, -1
    add a0, a0, t1

    ret
```

The linter should throw an error saying `_increment` has no explicit control-flow jump at the end (or perhaps just a warning).

Use case 2:
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

    add a0, t3

    ret

_other_function:
    li t3, 4
    add a0, a0, t3

    ret
```
Because push and pop don't cover `t3` we will be using `t3` when it could have been potentially clobbered by `_other_function`. Therefore, the linter
should probably throw something like "Error: use of volatile register after potential modification" or maybe something more friendly. God, I'm creating
the same error messages I abhor and don't bother to understand. Such as Rust's borrow checker errors. Maybe this is evidence that I should take more time
to learn what those other error messages are trying to tell me.


Note, the linter lints based on a "high-level programming language" model. There's a concept of `functions`, which are denoted between `call` and `return`
instructions, which are different from the control flow logic, used by jumps and branches. I'm not sure if that's indicative of good abstraction for assembly
or simply that I've been trained in "high-level programming languages" so I'd be interested to see what professional RiscV assembly looks like and if they 
follow a similar abstracted structure. There's no way to explicitly check if a function returns the
value in the right register (a0 or a1) but one could try to lint that based on comment docs in the assembly code. 


Use case(s) not covered by linter:
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


If I were to implement a linter, it would probably build off the work of https://austinhenley.com/blog/parsingriscv.html
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
