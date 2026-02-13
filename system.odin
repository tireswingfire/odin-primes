package primes
//system.odin - Operating system and command line interactions.

import "core:fmt"
import "core:time"
import "core:mem"
import "core:os"
import "core:strconv"
import "core:strings"

// Help message to print when -h or --help argument is passed
print_help_message :: proc() {
    fmt.print(
        "Usage:",
        "\t-n --count <int>      | Generate primes up to this limit",
        "\t-m --method <name>    | Method/algorithm to use",
        "\t\tTest     - Placeholder method",
        "\t-p --profile          | Track time elapsed and memory usage",
        "\t-o --output <path>    | Output file to export to",
        "\t-h --help             | Show this help message",
        "\n",
    sep="\n")
}

// Parses command line arguments and populates a configuration struct accordingly
parse_clargs_config :: proc() -> (config: Config, ok: bool) {
    // Initialize config to default; return if no arguments were passed
    config = default_cfg
    if len(os.args) <= 1 do return config, true

    // Invalid argument messenger
    invalid :: proc(message: string) {
        fmt.eprintln("Error:", message)
        print_help_message()
    }

    // Parse arguments
    for arg, i in os.args {
        switch arg {
        // Help argument
        case "-h", "--help":
            print_help_message()
            config.help = true

        // Upper limit argument
        case "-n", "--count":
            if i+1 >= len(os.args) { // Check for next arg
                invalid("An integer argument is required for -n / --count.")
                return {}, false
            }
            n, ok := strconv.parse_int(os.args[i+1]) // Parse next arg
            if !ok { // Next arg must be integer
                invalid(fmt.tprintf("Invalid integer for -n / --count: %q", os.args[i+1]))
                return {}, false
            }
            config.n = n

        // Method selection argument
        case "-m", "--method":
            if i+1 >= len(os.args) { // Check for next arg
                invalid("A method name argument is required for -m / --method.")
                return {}, false
            }
            valid := false
            for m in METHODS { // Search and match next arg in METHODS, case insensitive
                if strings.equal_fold(os.args[i+1], m.name) {
                    config.method = m
                    valid = true
                }
            }
            if !valid { // Next arg must be a valid method in METHODS
                invalid(fmt.tprintf("Invalid method name for -m / --method: %q", os.args[i+1]))
                return {}, false
            }

        // Output file path argument
        case "-o", "--output":
            if i+1 >= len(os.args) {
                invalid("A file path is required for -o / --output.")
                return {}, false
            } // Check for next arg
            config.output = os.args[i+1] // Next arg is taken at face value
            
        // Profiling argument
        case "-p", "--profile":
            config.profile = true // Simple boolean argument
        }
    }
    
    return config, true
}

// Writes a slice of integers to file, newline-separated
write_primes_to_file :: proc(filename: string, primes: []int) -> os.Error {
    // Open and defer closing of file; return upon error
    file, err := os.open(filename, os.O_WRONLY | os.O_CREATE | os.O_TRUNC, 0o644)
    if err != nil {
        fmt.eprintfln("Failed to open output file %q: %v", filename, err)
        return err
    }
    defer os.close(file)
    
    // Write slice values to file, newline-separated; return upon interruption\
    for p in primes {
        bytes_printed := fmt.fprintfln(file, "%d", p)
        if bytes_printed <= 0 {
            fmt.eprintfln("Write failed on prime %d", p)
            return os.ERROR_OPERATION_ABORTED
        } 
    }
    
    return nil
}

// Runs the passed procedure and tracks time elapsed and memory usage.
// Compatible only with procedures of signature: (int) -> []int.
profile_proc :: proc(proc_to_profile: proc(n: int, allocator := context.allocator) -> ([]int, bool), n: int, label: string = "Unnamed") -> (primes: []int, ok: bool) {
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
    primes, ok = proc_to_profile(n)
    time.stopwatch_stop(&timer)
    if !ok { // Handle errors
        fmt.eprintfln("Profiled function %q failed for n = %d", label, n)
        return nil, false
    }

    // Get elapsed time in milliseconds
    elapsed_ms := f64(time.duration_milliseconds(time.stopwatch_duration(timer)))

    // Print profile results to console
    fmt.printfln("Profile: %s =====", label)
    fmt.printfln("Time:    %.3f ms", elapsed_ms)
    fmt.printfln("Maximum: %d", n)
    fmt.printfln("Memory allocation =====")
    fmt.printfln("Peak:    %v bytes", mem_tracker.peak_memory_allocated)
    fmt.printfln("Total:   %v bytes", mem_tracker.total_memory_allocated)

    return primes, ok
}
