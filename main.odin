package primes
//main.odin - Entry point and main control flow.

Config :: struct {
    n:         int,
    method:    Method,
    profile:   bool,
    output:    string,
}

DEFAULT_CFG: Config: {
    n = 100,
    method = METHODS[0],
    profile = false,
    output = "primes.txt"
}

// Entry point; main procedure
main :: proc() {
    // Parse command line arguments
    cfg := parse_clargs_config()

    // Generate primes
    primes: []int
    if cfg.profile {
        // Generate primes with profiling
        primes = profile_proc(cfg.method.generate, cfg.n, cfg.method.name)
    }
    else {
        // Generate primes without profiling
        primes = cfg.method.generate(cfg.n)
    }

    // Write to file
    write_primes_to_file(cfg.output, primes)
}
