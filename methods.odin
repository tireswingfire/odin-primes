// methods.odin - A collection of various methods for generating prime numbers.
package primes

import "core:math"
import "core:fmt"

// Pairs a procedure with a name and a description
Method :: struct {
    name: string,
    description: string,
    generate: proc(pbits: ^PrimalityBitArray, n: u64, allocator := context.allocator) -> (ok: bool)
}

// Method registry; pairs each procedure below with a name and description
METHODS :: []Method {
    {"Test",
    "Dummy method, outputs only the very first prime, 2.",
    primes_test},

    {"Naive",
    "Trial division v1: Naive trial division method, modulus check on all divisors between 2 and sqrt(c).",
    primes_tridiv_naive},

    {"Prime",
    "Trial division v2: Like v1, but only does modulus checks on PRIME divisors between 2 and sqrt(c).",
    primes_tridiv_prime},

    {"Odds",
    "Trial division v3: Like v2, but only checks odd candidates > 3.",
    primes_tridiv_odds},

    {"PBits",
    "Trial division v4: Like v3, but operates directly within a primality bit array for reduced memory usage.",
    primes_tridiv_pbits},

    {"Eratos",
    "Sieve of Eratosthenes: The original sieve; Iteratively mark as composite the multiples of each prime.",
    primes_sieve_eratos},
}

// Dummy method, returns an empty bit array
primes_test :: proc(pbits: ^PrimalityBitArray, n: u64, allocator := context.allocator) -> (ok: bool) {
    return true
}

// Naive trial division method, generates primes up to max value n
// 
// For each candidate `c` from 2 to `n`, performs a modulus check on all divisors `d` between 2 and `sqrt(c)`
primes_tridiv_naive :: proc(pbits: ^PrimalityBitArray, n: u64, allocator := context.allocator) -> (ok: bool) {
    // Checks if a candidate c is prime by performing a
    // modulus check on all divisors between 2 and sqrt(c)
    is_prime :: proc(c: u64) -> bool {
        // d_max := c        // Naive approach; Check all divisors up to c
        // d_max := c/2      // Better; All factors will obviously be <= c/2
        // d_max := sqrt(c)  // Best; Factors come in pairs; If c/d = x R0, then c/x = d R0.
        d_max := u64(math.sqrt(f64(c)))
        for d: u64 = 2; d <= d_max; d += 1 {
            if c % d == 0 do return false
        }
        return true
    }

    // Clear the bit array to 0
    clear_pbits(pbits)
    // Dynamic array has negligible overhead in this case.
    list := make([dynamic]u64, 0, 8)
    // Check all candidates from 2 to n
    for c: u64 = 2; c <= n; c += 1 {
        if is_prime(c) do append(&list, c)
    }
    // Pack list into a PrimalityBitArray
    ok = pack_candidates(pbits, list[:], allocator)
    return ok
}

// Prime trial division method, generates primes up to max value n
// 
// For each candidate `c` from 2 to `n`, performs a modulus check on all PRIME divisors `d` between 2 and `sqrt(c)` **
primes_tridiv_prime :: proc(pbits: ^PrimalityBitArray, n: u64, allocator := context.allocator) -> (ok: bool) {
    // Clear the bit array to 0
    clear_pbits(pbits)
    // Dynamic array has negligible overhead in this case.
    list := make([dynamic]u64, 0, 8)
    // Check all candidates from 2 to n
    for c: u64 = 2; c <= n; c += 1 {
        // Modified is_prime() trial division; uses current list of primes as divisors
        c_is_prime := true
        d_max := u64(math.sqrt(f64(c)))
        // Get divisors from current list of primes **
        for d in list {
            if d > d_max do break
            if c % d == 0 {
                c_is_prime = false
                break
            } 
        }
        if c_is_prime do append(&list, c)
    }
    ok = pack_candidates(pbits, list[:], allocator)
    return ok
}

// Modified prime trial division method, generates primes up to max value n
// but only checks odd candidates. **
// 
// For each odd candidate c from 3 to `n`, performs a modulus check on all PRIME divisors between 3 and `sqrt(c)`
primes_tridiv_odds :: proc(pbits: ^PrimalityBitArray, n: u64, allocator := context.allocator) -> (ok: bool) {
    // Clear the bit array to 0
    clear_pbits(pbits)
    // Dynamic array has negligible overhead in this case.
    list := make([dynamic]u64, 0, 8)
    // Start with 2 explicitly, all others will be odd
    append(&list, 2)
    // Check all odd candidates from 3 to n **
    for c: u64 = 3; c <= n; c += 2 {
        // Modified is_prime() trial division; uses current list of primes as divisors
        c_is_prime := true
        d_max := u64(math.sqrt(f64(c)))
        // Get divisors from current list of primes
        for d in list {
            if d > d_max do break
            if c % d == 0 {
                c_is_prime = false
                break
            } 
        }
        if c_is_prime do append(&list, c)
    }
    ok = pack_candidates(pbits, list[:], allocator)
    return ok
}

// Modified prime trial division method, generates primes up to max value n.
// Works directly inside a PrimalityBitArray instead of a [dynamic]u64 **
// 
// For each odd candidate `c` from 3 to `n`, performs a modulus check on all PRIME divisors between 2 and `sqrt(c)`
primes_tridiv_pbits :: proc(pbits: ^PrimalityBitArray, n: u64, allocator := context.allocator) -> (ok: bool) {
    // Clear the bit array to 0
    clear_pbits(pbits)
    // No more dynamic array **
    // Check all odd candidates from 3 to n
    for c: u64 = 3; c <= n; c += 2 {
        // Modified is_prime() trial division; uses current list of primes as divisors
        c_is_prime := true
        d: u64
        d_max := u64(math.sqrt(f64(c)))
        // Iterator for PrimalityBitArray **
        piter := make_piterator(pbits)
        for {
            // Get next prime divisor from bit array **
            d, ok = next_set_candidate(&piter)
            if !ok || d > d_max do break
            if c % d == 0 {
                c_is_prime = false
                break
            } 
        }
        // Set bit for a prime candidate directly **
        if c_is_prime do ok = set_pbit_for(pbits, c)
        if !ok do return false
    }
    return true
}

// Sieve of Eratosthenes
primes_sieve_eratos :: proc(pbits: ^PrimalityBitArray, n: u64, allocator := context.allocator) -> (ok: bool) {
    // Clear the bit array to all 1 instead of all 0
    clear_pbits(pbits, true)
    // Iterator for PrimalityBitArray 
    piter := make_piterator(pbits)

    // Only use primes up to sqrt(n)
    p_max := u64(math.sqrt(f64(n)))
    p: u64
    // To increment candidate by 2p, skipping even numbers
    c_step := 2 * p

    // For each prime, mark all multiples composite
    for {
        // Get next prime in the bit array until sqrt(n) or end of array
        p, ok = next_set_candidate(&piter)
        if !ok || p > p_max do break
        
        // Mark all multiples of p composite
        c_step = 2 * p
        for c: u64 = p * p; c <= n; c += c_step {
            ok = unset_pbit_for(pbits, c)
            if !ok do return false
        }
    }
    return true
}