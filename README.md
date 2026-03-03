# odin-primes
An exercise in writing and optimizing prime number generators to familiarize myself with Odin. Below is a report of what I have practiced and learned with this project so far.

## Core Mathematical Concepts Explored
- Trial division
    - The most basic method for generating primes.
    - Remainder division or modulus operations on each number against some list of possible factors.
    - A naive implementation might check a number n against all divisors up to n, but it is faster to check only up to sqrt(n), as factors come in pairs.
- Sieve of Eratosthenes
    - The original sieve.
    - Iteratively marks as "composite" all multiples of each unmarked (prime) number.
    - Can be accelerated with a wheel and a bit array.
- Wheel factorization
    - Used to discard all mutiples of the first few primes (for practical reasons, typically only the first 3 to 5).
    - A wheel is constructed to only include numbers that are coprime with the product of the first few primes, and is then "rolled" along the number line to give a series of candidates, which can then be checked further in a sieve.
    - Reduces computation time and/or memory usage for most algorithms when leveraged correctly.

## Programming Techniques Practiced
- Command-line argument parsing (manual)
    - More flexible than Odin's built-in tag-based automatic parsing, but more fragile.
- Basic procedure profiling
    - Stopwatch & tracking memory allocator, hard-coded in Odin
- Procedure dispatch table
    - My `Method` struct + `METHODS` forms a procedure pointer table, accessible from the command line.
- Bit-packing (boolean bit arrays)
    - Booleans are typically one byte wide, but can be packed into a bit array of 1-bit-wide booleans.
    - Bit arrays are comprised of "words", typically unsigned integer types 1 to 8 bytes wide that form the backing array in memory.
- Wrappers
    - Sometimes it is beneficial to "wrap" an API into a "wrapper" API, either to simplify it, add functionality, improve flexibility, or adapt it to your particular use case.
    
## Odin-Specific Idiomatic Details Learned
- Heap allocation
    - `new()` allocates for a single value of any type, returns a pointer.
        - `free()` to deallocate
    - `make()` allocates and constructs one of Odin's built-in dynamic collection types, such as a slice or a dynamic array.
        - `delete()` to deallocate
- Defer functionality
    - Odin has a `defer` keyword that queues code to run at the END of a given scope. Can and should often be used for `delete()` and other cleanup / deallocations, written right after allocation for readability.
    - Deferred statements run in LIFO (last-in, first-out) order, like a stack.
- Procedure parameters
    - Parameters like `#optional_ok` and `#force_inline` change the behavior of procedures in the eyes of the compiler.
- Context system
    - One of Odin's killer features is the "context" system, where a context struct is automatically passed by pointer to nearly every procedure call. It contains, among other things:
        - A primary memory allocator `allocator`
        - A temporary memory allocator `temp_allocator`
        - A debug logger `logger`
        - A free-to-use user pointer `user_ptr`
    - Can be used to "inject" behavior into code you don't control (libraries, etc), all WITHOUT changing any function signatures.
- Error propagation
    - Most common idiomatic way of handling errors in Odin is to propagate either an "ok" boolean or an "err" OS error type back through a call chain. Usually the final return value of a procedure, and `#optional_ok` allows you to ignore it when you call the procedure.
- Explicit Procedure overloading
    - Odin has explicit procedure overloading, for when a procedure needs to handle different types of arguments with different implementations, such that using generics will not suffice.

## Documented Learning Process
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

#### 2026-03-02 - Sieve of Eratosthenes
- The original sieve for generating prime numbers.
    - Works by iteratively marking "composite" all multiples of every unmarked (prime) number, starting with 2.
    - Can be optimized by pairing it with a wheel-based bit array to skip all multiples of a few very small primes.

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