// methods.odin - A collection of various methods for generating prime numbers.
package primes

import "core:math"

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
    "Trial division v4: Like v3, but operates directly within a primality bit array for reduced memory usage",
    primes_tridiv_pbits},
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