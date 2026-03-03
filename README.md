# odin-primes
An exercise in writing and optimizing prime number generators to familiarize myself with Odin.

## What I have learned so far
#### 2026-02-14 - Dynamic arrays and trial division
- `[dynamic]` arrays in odin double their capacity when append() reaches the cap. This results in very few reallocation calls for ever-growing arrays (roughly one realloc for every doubling in size). Overhead vs pre-allocated arrays is therefore often negligible, unless dealing with many different growing arrays.
- Factors come in pairs; For trial division, I only need to check factors up to sqrt(c) to determine if a candidate c is prime or not. Previously my assumption was c / 2.
    - Trial division can also be further narrowed to only prime factors. Very convenient for a sequential trial division generator.

#### 2026-02-18 - Procedure parameters and bit arrays
- `#no_bounds_check` is useful but dangerous - reduces runtime overhead by telling the compiler not to generate bound-checking code, but opens the door to out-of-bounds read/writes and undefined behavior.
- `#optional_ok` allows the caller to skip the last return value, which needs to be a bool.
- `#force_inline` forces the compiler to make the body of a proc inline with the calling code.
- Just discovered that odin has a bit array and bit array iterator IN THE CORE LIBRARY! Instead of implementing it myself, just read the docs, dummy!

#### 2026-02-19 - Wrappers and documentation
- Learned deeper into what a wrapper is and built a thin one; my `PrimalityBitArray` and associated procs thinly wrap `core:containers/bit_array`
- Learned how to use VSCode-readable markdown comments for documentation: 
    - `// Comments automatically document the following declaration `
    - `// *This comment is in italics* `
    - `// **This comment is in bold** `
    - ```// `This comment is in a single-line code block` ```

#### 2026-02-20 - Explicit procedure overloading
- Odin has explicit procedure overloading! core:math has:
    ``` 
    sqrt :: proc {
        sqrt_f16,
        sqrt_f32,
        sqrt_f64,
        . . .,
    } 
    . . . 
    sqrt_f16 :: proc "contextless" (x: f16) -> f16 { return intrinsics.sqrt(x) }
    sqrt_f32 :: proc "contextless" (x: f32) -> f32 { return intrinsics.sqrt(x) }
    sqrt_f64 :: proc "contextless" (x: f64) -> f64 { return intrinsics.sqrt(x) }
    ```
    - sqrt() branches depending on the type of float you pass in

#### 2026-02-21 - Wheel factorization
- Had an idea: Generalize the concept of an odd-numbers-only (not divisible by 2) bit array; What if we tracked only numbers that weren't divisible by the first few primes?
    - Turns out, that's a thing. It's called wheel factorization.
    - Will attempt to implement a wheel-based bit array as a more flexible (and potentially faster / more memory efficient) generalization of my PrimalityBitArray

## Profiling example 2026-03-02
```
.\odin-primes.exe -m Naive -n 1_000_000 -p 
Profile: Naive  ==========
  Time:      504.592 ms
  Primes:    78498
  Maximum:   1000000
  Wheel lvl: 1
Memory Allocation  =======
  Total:     2158.960 kiB

.\odin-primes.exe -m Prime -n 1_000_000 -p
Profile: Prime  ==========
  Time:      134.423 ms
  Primes:    78498
  Maximum:   1000000
  Wheel lvl: 1
Memory Allocation  =======
  Total:     2158.960 kiB

.\odin-primes.exe -m Odds -n 1_000_000 -p 
Profile: Odds   ==========
  Time:      125.537 ms
  Primes:    78498
  Maximum:   1000000
  Wheel lvl: 1
Memory Allocation  =======
  Total:     2158.960 kiB

.\odin-primes.exe -m Pbits -n 1_000_000 -p
Profile: PBits  ==========
  Time:      637.673 ms
  Primes:    78498
  Maximum:   1000000
  Wheel lvl: 1
Memory Allocation  =======
  Total:     62.832 kiB

.\odin-primes.exe -m Eratos -n 1_000_000 -w 1 -p 
Profile: Eratos ==========
  Time:      67.562 ms
  Primes:    78498
  Maximum:   1000000
  Wheel lvl: 1
Memory Allocation  =======
  Peak:      62.832 kiB
  Total:     62.832 kiB

.\odin-primes.exe -m Eratos -n 1_000_000 -w 2 -p
Profile: Eratos ==========
  Time:      36.772 ms
  Primes:    78498
  Maximum:   1000000
  Wheel lvl: 2
Memory Allocation  =======
  Peak:      42.000 kiB
  Total:     42.000 kiB

.\odin-primes.exe -m Eratos -n 1_000_000 -w 3 -p
Profile: Eratos ==========
  Time:      28.776 ms
  Primes:    78498
  Maximum:   1000000
  Wheel lvl: 3
Memory Allocation  =======
  Peak:      33.664 kiB
  Total:     33.664 kiB

.\odin-primes.exe -m Eratos -n 1_000_000 -w 4 -p
Profile: Eratos ==========
  Time:      30.272 ms
  Primes:    78498
  Maximum:   1000000
  Wheel lvl: 4
Memory Allocation  =======
  Peak:      29.288 kiB
  Total:     29.544 kiB

.\odin-primes.exe -m Eratos -n 1_000_000 -w 5 -p
Profile: Eratos ==========
  Time:      98.244 ms
  Primes:    78498
  Maximum:   1000000
  Wheel lvl: 5
Memory Allocation  =======
  Peak:      30.272 kiB
  Total:     33.920 kiB

.\odin-primes.exe -m Eratos -n 1_000_000 -w 6 -p
Profile: Eratos ==========
  Time:      796.446 ms
  Primes:    78498
  Maximum:   1000000
  Wheel lvl: 6
Memory Allocation  =======
  Peak:      89.712 kiB
  Total:     154.544 kiB
```