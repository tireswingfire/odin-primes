package primes
//main.odin - Entry point and main control flow.

import "core:fmt"
import "core:os"

Config :: struct {
    n:         int,
    method:    Method,
    profile:   bool,
    output:    string,
    help:      bool,
}

DEFAULT_CFG: Config: {
    n = 100,
    method = METHODS[0],
    profile = false,
    output = "primes.txt",
    help = false,
}

// Entry point; main procedure
main :: proc() {
    // Exit procedure
    exit :: proc(code: int, message: string = "") {
        fmt.eprintln(message)
        os.exit(code)
    }

    // Parse command line arguments
    cfg, ok := parse_clargs_config()
    if !ok do exit(1, "Failed to parse command line arguments!")
    
    // Exit early if help argument was passed
    if cfg.help do os.exit(0)

    // Generate primes
    primes: []int
    if cfg.profile {
        // Generate primes with profiling
        primes, ok = profile_proc(cfg.method.generate, cfg.n, cfg.method.name)
    }
    else {
        // Generate primes without profiling
        primes, ok = cfg.method.generate(cfg.n)
    }
    if !ok do exit(1, "Failed to generate primes!")

    // Write to file
    write_primes_to_file(cfg.output, primes)
    if !ok do exit(1, "Failed to write primes to file!")
}
