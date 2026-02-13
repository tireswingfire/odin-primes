package primes
//main.odin - Entry point and main control flow.

import "core:flags"
import "core:os"

Config :: struct {
    n:         int    `args:"name=n,required" usage:"Generate primes up to this limit" default:"100"`,
    method:    string `args:"name=m" usage:"Method/algorithm to use"`,
    profile:   bool   `args:"name=p" usage:"Show time taken and memory usage"`,
    output:    string `args:"name=o" usage:"Output file path; default is primes.txt"`,
}

DEFAULT_CFG: Config: {
    n = 100,
    method = "Test",
    profile = false,
    output = "primes.txt"
}

// Entry point; main procedure
main :: proc() {
    // Parse command line arguments
    cfg := DEFAULT_CFG
    flags.parse_or_exit(&cfg, os.args)
    // Default to first method in list
    method := METHODS[0]
    for m in METHODS {
        if cfg.method == m.name do method = m
    }
    
    // Generate primes
    primes: []int
    if cfg.profile {
        // Generate primes with profiling
        primes = profile_proc(method.generate, cfg.n, method.name)
    }
    else {
        // Generate primes without profiling
        primes = method.generate(cfg.n)
    }

    // Write to file
    write_primes_to_file(cfg.output, primes)
}
