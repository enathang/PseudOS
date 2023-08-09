The ABI defines the convention of how to write RiscV assembly such that it can interact with other assembly without unexpected side effects.

Some rules of thumb:
- all tx and ax registers are not guaranteed to be saved
- all sx registers are guaranteed to be saved

Changes required to be in compliance with ABI:
Honestly, not that much. We need to switch return values from a2 to a0, make sure we never modify sx or restore it after we do

We also need to initialize global pointer

References:
https://www.youtube.com/watch?v=ovpG0R-4F8k (linked github textbook in description useful as well)
