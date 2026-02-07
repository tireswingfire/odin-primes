package primes

import "core:fmt"
import "core:os"

PROFILING_ENABLED :: true

main :: proc() {
    n: int = 100

    // Create and defer destruction of a heap-allocated array for storing primes
    primes: []int = make([]int, n)
    defer delete(primes)

    if PROFILING_ENABLED {
        // Generate primes with profiling
        profile_proc(generate_primes_test, &primes)
    }
    else {
        // Generate primes without profiling
        generate_primes_test(&primes)
    }

    // Write array to file, newline-separated
    file, err := os.open("output.txt", os.O_WRONLY | os.O_CREATE | os.O_TRUNC, 0o644)
    defer os.close(file)
    if err != nil do fmt.printfln("ERROR: %s", err)
    for p in primes {
        if p != 0 do fmt.fprintfln(file, "%i", p)
    }
}

generate_primes_test :: proc(primes: ^[]int) {
    primes[0] = 2
}