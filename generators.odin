package primes
//generators.odin - A collection of procedures that generate prime numbers using a variety of methods

import "core:fmt"

gen_primes_test :: proc(n: int) -> []int {
    primes: [dynamic]int
    defer delete(primes)
    append(&primes, 2)

    return primes[:]
}