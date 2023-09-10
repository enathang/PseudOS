Notes on locking:

The term concurrency refers to situations in which multiple instructions can/are interleaved, due to multiple parallel CPUs, thread
switching on a single CPU, or interrupts.

Concurrency is good for performance, but we need higher-level abstractions to enforce correctness under concurrency. Hence we use locks.

Here we cover two main types of locks: spinlocks and sleep-locks.

Spinlocks:
Allow mutual exclusion. Note, if checking and updating the lock are two separate instructions, race conditions can still occur with multiple threads
thinking they own the lock. Therefore, most instruction sets support an `atomic` instruction to read and udpate a lock.


