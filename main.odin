package primes
//main.odin - Entry point and main control flow.

Config :: struct {
    n:         int,
    method:    string,
    profile:   bool,
    output:    string,
}

DEFAULT_CFG: Config: {
    n = 100,
    method = METHODS[0].name,
    profile = false,
    output = "primes.txt"
}

// Entry point; main procedure
main :: proc() {
    // Parse command line arguments
    cfg := parse_clargs_config()
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
