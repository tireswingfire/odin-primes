package primes
//system.odin - Operating system interactions

import "core:fmt"
import "core:time"
import "core:mem"
import "core:os"

// Runs the passed procedure and tracks time elapsed and memory usage.
// Compatible only with procedures of signature: (int) -> []int.
profile :: proc(proc_to_profile: proc(int) -> []int, n: int, label: string = "Unnamed") -> []int {
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
    primes := proc_to_profile(n)
    time.stopwatch_stop(&timer)

    // Get elapsed time in milliseconds
    elapsed_ms := f64(time.duration_milliseconds(time.stopwatch_duration(timer)))

    // Print profile results to console
    fmt.printfln("Profile: %s =====", label)
    fmt.printfln("Time:    %.3f ms", elapsed_ms)
    fmt.printfln("Primes:  %d", n)
    fmt.printfln("Memory allocation =====")
    fmt.printfln("Peak:    %v bytes", mem_tracker.peak_memory_allocated)
    fmt.printfln("Total:   %v bytes", mem_tracker.total_memory_allocated)

    return primes[:]
}

// Writes a slice of integers to file, newline-separated
write_primes_to_file :: proc(filename: string, primes: []int) {
    // Open and defer closing of file
    file, err := os.open(filename, os.O_WRONLY | os.O_CREATE | os.O_TRUNC, 0o644)
    defer os.close(file)
    
    // Write slice values to file, newline-separated
    if err != nil do fmt.printfln("ERROR: %s", err)
    for p in primes {
        if p != 0 do fmt.fprintfln(file, "%i", p)
    }
}
