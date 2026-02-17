package primes
//main.odin - Entry point and main control flow.

import "core:fmt"
import "core:os"
import "core:mem"
import "core:time"

Config :: struct {
    n:         u64,
    method:    Method,
    profiling: bool,
    output:    string,
    help:      bool,
}

default_cfg: Config: {
    n = 100,
    method = METHODS[0],
    profiling = false,
    output = "primes.txt",
    help = false,
}

// Entry point; main procedure
main :: proc() {
    // Parse command line arguments
    cfg, ok := parse_clargs_config()
    if !ok do exit(1, "Failed to parse command line arguments!")
    // Exit early if help argument was passed
    if cfg.help do exit(0)

    // Start memory tracking for profiling purposes
    mem_tracker: mem.Tracking_Allocator
    mem.tracking_allocator_init(&mem_tracker, context.allocator)
    context.allocator = mem.tracking_allocator(&mem_tracker)
    defer mem.tracking_allocator_destroy(&mem_tracker)

    // Array for storing primes
    primes: []u64
    defer delete(primes)

    // Generate primes (with timer if profiling); exit on failure
    timer: time.Stopwatch
    if cfg.profiling do time.stopwatch_start(&timer)
    primes, ok = cfg.method.generate(cfg.n, context.allocator)
    if !ok do exit(1, "Failed to generate primes!")
    if cfg.profiling do time.stopwatch_stop(&timer)
    
    // Print profile results to console
    if cfg.profiling {
        // Get elapsed time in milliseconds
        elapsed_ms := f64(time.duration_milliseconds(time.stopwatch_duration(timer)))

        fmt.printfln("Profile: %s =====", cfg.method.name)
        fmt.printfln("Time:    %.3f ms", elapsed_ms)
        fmt.printfln("Maximum: %d", cfg.n)
        fmt.printfln("Memory allocation =====")
        fmt.printfln("Peak:    %v B", mem_tracker.peak_memory_allocated)
        fmt.printfln("Total:   %v B", mem_tracker.total_memory_allocated)
    }
    
    // Write to file
    err := write_primes_to_file(cfg.output, primes)
    if err != nil do exit(1, "Failed to write primes to file!")
}

// Exit procedure
exit :: proc(code: int, message: string = "") {
    if message != "" do fmt.eprintln(message)
    os.exit(code)
}