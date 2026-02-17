package primes
//methods.odin - A collection of various methods for generating prime numbers.
import "core:c"

import "core:math"

// Name-procedure pair for methods
Method :: struct {
    name: string,
    description: string,
    generate: proc(n: u64, allocator := context.allocator) -> ([]u64, bool)
}

// Method registry; pairs each generator below with a name (string)
METHODS :: []Method {
    {"Test", "Placeholder generator, returns only the very first prime, 2.", primes_test},
    {"Naive", "Naive generator, modulus check on all divisors between 2 and sqrt(c)", primes_naive},
}

// Placeholder generator, returns only the very first prime, 2.
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

// Naive method, generates primes up to max value n.
// For each candidate c, performs a modulus check on all divisors between 2 and sqrt(c). 
primes_naive :: proc(n: u64, allocator := context.allocator) -> ([]u64, bool) {
    // Dynamic array has negligible overhead in this case.
    primes := make([dynamic]u64)
    // Check all integers from 2 to n
    for c: u64 = 2; c <= n; c += 1 {
        // Modulus check
        if is_prime(c) do append(&primes, c)
    }
    return primes[:], true
}
