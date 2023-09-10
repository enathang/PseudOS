# A hardware/OS visualizer

The idea of a visualizer to display the hardware/software interactions keeps popping up into my head. So, I thought I'd jot some notes down on the topic.

## What I want
A website that has boxes for each registers (grouped together and color-coded based on use) and can run code to update the register/memory values. You can see code running in real-time. 

Potentially, you could also add annotations to visualize software abstractions such as a page table. Is there an existing language that can specify this? I'm imagining a diagramming language where you can write code (such as alloy) and it visualizes the data based on your writing. 

```
<group type='csr'>
    <register id='mepc'>
</group>
<page_table>
</page_table>
```
Can this be generated via llm? Seems useful to remove grunt-work.
```
mepc # %= mepc
```

## Existing solutions
https://wiki.osdev.org/QEMU_Monitor

Can we build a typescript front for QEMU monitor?
