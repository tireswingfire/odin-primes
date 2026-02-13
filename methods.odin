package primes
//methods.odin - A collection of various methods for generating prime numbers.

// Name-procedure pair for methods
Method :: struct {
    name: string,
    generate: proc(n: int) -> []int
}

// Method registry; pairs each method below with a name (string)
METHODS :: []Method {
    {"Test", gen_primes_test},
}

// Placeholder method, returns only the very first prime, 2.
gen_primes_test :: proc(n: int) -> (primes: []int) {
    primes = make([]int, 1)
    defer delete(primes)
    primes[0] = 2

    return primes[:]
}