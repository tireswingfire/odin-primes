package primes
//methods.odin - A collection of various methods for generating prime numbers.

// Name-procedure pair for methods
Method :: struct {
    name: string,
    description: string,
    generate: proc(n: int, allocator := context.allocator) -> ([]int, bool)
}

// Method registry; pairs each generator below with a name (string)
METHODS :: []Method {
    {"Test", "Description", primes_test},
}

// Placeholder generator, returns only the very first prime, 2.
primes_test :: proc(n: int, allocator := context.allocator) -> (primes: []int, ok: bool) {
    primes = make([]int, 1)
    primes[0] = 2

    return primes[:], true
}