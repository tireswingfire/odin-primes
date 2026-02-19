# odin-primes
An exercise in optimizing prime-number generators to familiarize myself with Odin.

## What I have learned so far:
#### As of 2026-02-14 - Dynamic arrays and trial division
- `[dynamic]` arrays in odin double their capacity when append() reaches the cap. This results in very few reallocation calls for ever-growing arrays (roughly one realloc for every doubling in size). Overhead vs pre-allocated arrays is therefore often negligible, unless dealing with many different growing arrays.
- Factors come in pairs; For trial division, I only need to check factors up to sqrt(c) to determine if a candidate c is prime or not. Previously my assumption was c / 2.
    - Trial division can also be further narrowed to only prime factors. Very convenient for a sequential trial division generator.

#### As of 2026-02-18 - no-bounds-check
- `#no-bounds-check` is useful but dangerous - reduces runtime overhead by telling the compiler not to generate bound-checking code, but opens the door to out-of-bounds read/writes and undefined behavior.