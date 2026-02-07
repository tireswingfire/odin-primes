package primes

import "core:fmt"
import "core:time"
import "core:mem"

// Runs the passed procedure and tracks time elapsed and memory usage
// Compatible only with prime-generating procedures in odin-primes
profile_proc :: proc(proc_to_profile: proc(primes: ^[]int), primes: ^[]int, label: string = "Unnamed") {
    
    // Create and defer destruction of memory tracker
    mem_tracker: mem.Tracking_Allocator
    mem.tracking_allocator_init(&mem_tracker, context.allocator)
    defer mem.tracking_allocator_destroy(&mem_tracker)
    // Set current context allocator to the new tracking allocator
    context.allocator = mem.tracking_allocator(&mem_tracker)

    // Create stopwatch
    timer: time.Stopwatch

    // Profile the passed procedure
    time.stopwatch_start(&timer)
    proc_to_profile(primes)
    time.stopwatch_stop(&timer)

    // Get elapsed time in milliseconds
    elapsed_ms := f64(time.duration_milliseconds(time.stopwatch_duration(timer)))

    // Print profile results to console
    fmt.printfln("Profile: %s =====", label)
    fmt.printfln("Time:    %.3f ms", elapsed_ms)
    fmt.printfln("Primes:  %d", len(primes))
    fmt.printfln("Memory allocation =====")
    fmt.printfln("Peak:    %v bytes", mem_tracker.peak_memory_allocated)
    fmt.printfln("Total:   %v bytes", mem_tracker.total_memory_allocated)
}