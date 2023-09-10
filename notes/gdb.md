riscv64-unknown-elf-gdb build/kernel.elf 

Connect to the QEMU session with the command

    (gdb) target remote localhost:1234

Use this command to activate GDB's display of source and registers

    (gdb) tui reg general

Skip to the start of your code with

    (gdb) advance pmain
    advance _move_to_supervisor_mode

    (gdb) info registers mstatus

At this point, you can use the command step to execute your program one instruction at a time, and watch the register contents as you do so. It helps to enlarge the terminal window so that all the registers are visible. Once you have given the step command once, just pressing <Return> will step repeatedly.
When boredom overcomes you, use quit to quit.


qemu-system-riscv64 -machine virt -cpu rv64 -smp 4 -m 128M  -serial mon:stdio -bios none -kernel build/kernel.elf -device VGA -gdb tcp::9000 -S -g -O0


Ref:
- https://jvns.ca/blog/2021/05/17/how-to-look-at-the-stack-in-gdb/
