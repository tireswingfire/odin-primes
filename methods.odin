// methods.odin - A collection of various methods for generating prime numbers.
package primes

import "core:math"

// Name-procedure pair for methods
Method :: struct {
    name: string,
    description: string,
    generate: proc(pbits: ^PrimalityBitArray, n: u64, allocator := context.allocator) -> (ok: bool)
}

// Method registry; pairs each method below with a name (string)
METHODS :: []Method {
    {"Test",
     "Dummy method, outputs only the very first prime, 2.",
     primes_test},

    {"Naive",
     "Naive trial division method, modulus check on all divisors between 2 and sqrt(c).",
     primes_tridiv_naive},

    {"Prime",
    "Improved trial division method, modulus check on all PRIME divisors between 2 and sqrt(c).",
    primes_tridiv_prime},
}

// Dummy method, returns an empty bit array
primes_test :: proc(pbits: ^PrimalityBitArray, n: u64, allocator := context.allocator) -> (ok: bool) {
    return true
}

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

// Naive trial division method, generates primes up to max value n
// 
// For each candidate c, performs a modulus check on all divisors between 2 and sqrt(c)
primes_tridiv_naive :: proc(pbits: ^PrimalityBitArray, n: u64, allocator := context.allocator) -> (ok: bool) {
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
// For each candidate c, performs a modulus check on all PRIME divisors between 2 and sqrt(c)
primes_tridiv_prime :: proc(pbits: ^PrimalityBitArray, n: u64, allocator := context.allocator) -> (ok: bool) {
    // Dynamic array has negligible overhead in this case.
    list := make([dynamic]u64, 0, 8)
    // Check all candidates from 2 to n
    for c: u64 = 2; c <= n; c += 1 {
        // Modified is_prime() trial division; uses current list of primes as divisors
        c_is_prime := true
        d_max := u64(math.sqrt(f64(c)))
        for p in list {
            if p > d_max do break
            if c % p == 0 {
                c_is_prime = false
                break
            } 
        }
        if c_is_prime do append(&list, c)
    }
    ok = pack_candidates(pbits, list[:], allocator)
    return ok
}
