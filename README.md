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

## Profiling example 2026-02-20
```
.\odin-primes.exe -m pbits -n 10_000_000 -p
Profile:  PBits  =====
Time:     7632.439 ms
Maximum:  10_000_000
Primes:   664579
Memory allocation  =====
Peak:     625.064 kiB
Total:    625.064 kiB

.\odin-primes.exe -m odds -n 10_000_000 -p 
Profile:  Odds  =====
Time:     2367.327 ms
Maximum:  10_000_000
Primes:   664579
Memory allocation  =====
Peak:     9013.608 kiB
Total:    17401.064 kiB

.\odin-primes.exe -m prime -n 10_000_000 -p
Profile:  Prime  =====
Time:     2530.478 ms
Maximum:  10_000_000
Primes:   664579
Memory allocation  =====
Peak:     9013.608 kiB
Total:    17401.064 kiB

.\odin-primes.exe -m naive -n 10_000_000 -p 
Profile:  Naive  =====
Time:     14020.858 ms
Maximum:  10_000_000
Primes:   664579
Memory allocation  =====
Peak:     9013.608 kiB
Total:    17401.064 kiB
```