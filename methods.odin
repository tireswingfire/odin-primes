package primes
//methods.odin - A collection of various methods for generating prime numbers.

import "core:c"
import "core:math"
import "core:fmt"

// Name-procedure pair for methods
Method :: struct {
    name: string,
    description: string,
    generate: proc(n: u64, allocator := context.allocator) -> ([]u64, bool)
}

// Method registry; pairs each method below with a name (string)
METHODS :: []Method {
    {"Test", "Placeholder method, returns only the very first prime, 2.", primes_test},
    {"NaiveTD", "Naive trial division method, modulus check on all divisors between 2 and sqrt(c)", primes_tridiv_naive},
    {"PrimeTD", "Improved trial division method, modulus check on all PRIME divisors between 2 and sqrt(c)", primes_tridiv_prime},
    {"PackedTD", "EXPERIMENTAL - Prime trial division method modified to work with a bitpacked bool array", primes_tridiv_packed_temp},
}

// Placeholder method, returns only the very first prime, 2.
primes_test :: proc(n: u64, allocator := context.allocator) -> ([]u64, bool) {
    primes := make([]u64, 1)
    primes[0] = 2

    return primes[:], true
}

// Checks if a candidate c is prime by performing a
// modulus check on all divisors between 2 and sqrt(c). 
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

// Naive trial division method, generates primes up to max value n.
// For each candidate c, performs a modulus check on all divisors between 2 and sqrt(c). 
primes_tridiv_naive :: proc(n: u64, allocator := context.allocator) -> ([]u64, bool) {
    // Dynamic array has negligible overhead in this case.
    primes := make([dynamic]u64, 0, 8)
    // Check all candidates from 2 to n
    for c: u64 = 2; c <= n; c += 1 {
        if is_prime(c) do append(&primes, c)
    }
    return primes[:], true
}

// Prime trial division method, generates primes up to max value n.
// For each candidate c, performs a modulus check on all PRIME divisors between 2 and sqrt(c).
primes_tridiv_prime :: proc(n: u64, allocator := context.allocator) -> ([]u64, bool) {
    // Dynamic array has negligible overhead in this case.
    primes := make([dynamic]u64, 0, 8)
    // Check all candidates from 2 to n
    for c: u64 = 2; c <= n; c += 1 {
        // Modified is_prime() trial division; uses current list of primes as divisors
        c_is_prime := true
        d_max := u64(math.sqrt(f64(c)))
        for p in primes {
            if p > d_max do break
            if c % p == 0 {
                c_is_prime = false
                break
            } 
        }
        if c_is_prime do append(&primes, c)
    }
    return primes[:], true
}



// EXPERIMENTAL - Prime trial division method modified to work with a bitpacked bool array
primes_tridiv_packed :: proc(n: u64, allocator := context.allocator) -> (primes: PrimeBits, ok: bool) {
    primes.data = make([dynamic]u8, 1, 8)
    // Start at 3, skip even numbers
    for c: u64 = 3; c <= n; c += 2 {
        // Grow bit array if needed
        if !has_bit_for(c, &primes) do append(&primes.data, 0)
        // Modified trial division check
        c_is_prime := true
        d_max := u64(math.sqrt(f64(c)))
        // Back to iterating over all odd divisors, this is slow. TODO optimize
        for d: u64 = 3; d <= d_max; d += 2 {
            // If divisor is a prime factor of candidate, c is not prime
            if read_bit_for(d, &primes) && c % d == 0 {
                c_is_prime = false
                break
            }
        }
        if c_is_prime do set_bit_for(c, true, &primes)
    }
    return primes, true
}

// Temporary fix - must fit the proc signature required for Method.generate
primes_tridiv_packed_temp :: proc(n: u64, allocator := context.allocator) -> ([]u64, bool) {
    primebits, _ := primes_tridiv_packed(n, allocator)
    return unpack_primes(&primebits)[:], true
}