package primes
//main.odin - Entry point and main control flow

import "core:fmt"

N :: 100
PROFILING_ENABLED :: true
OUTPUT_FILE :: "output.txt"

Algorithm :: enum {
    Test,
}

main :: proc() {
    primes: []int
    
    // Use the proxy function to generate primes
    primes = generate_primes(N, .Test, PROFILING_ENABLED)

    // Write to file
    write_primes_to_file(OUTPUT_FILE, primes)
}

generate_primes :: proc(n: int, algorithm: Algorithm = .Test, profiling_enabled: bool = false) -> []int {
    // Pick a generator depending on the specified algorithm
    generator: proc(int) -> []int
    switch algorithm {
        case .Test:
            generator = gen_primes_test
    }

    if profiling_enabled {
        // Generate primes with profiling
        return profile(generator, n, "Test profile")[:]
    }
    else {
        // Generate primes without profiling
        return generator(n)[:]
    }
}
