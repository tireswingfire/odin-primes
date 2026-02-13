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
        "Usage:\n",
        "\t-n --count <int>      | Generate primes up to this limit\n",
        "\t-m --method <string>  | Method/algorithm to use\n",
        "\t\tTest     - Placeholder method\n",
        "\t-p --profile          | Track time elapsed and memory usage\n",
        "\t-o --output <path>    | Output file to export to\n",
    sep="")
}

// Parses command line arguments and populates a configuration struct accordingly
parse_clargs_config :: proc() -> (config: Config) {
    // Initialize to default; return if no arguments were passed
    config = DEFAULT_CFG
    if len(os.args) == 1 do return config

    // Invalid argument handler
    invalid :: proc(message: string) {
        fmt.println("Invalid argument:", message)
        print_help_message()
        os.exit(1)
    }

    // Help message argument
    if os.args[1] == "-h" || os.args[1] == "--help" {
        print_help_message()
        os.exit(0)
    }

    // Operational arguments
    for arg, i in os.args {
        switch arg {
        case "-n", "--count":
            err_message := "Must provide an integer following -n or --count."
            if len(os.args) == i + 1 do invalid(err_message) // Check for next arg
            n, ok := strconv.parse_int(os.args[i + 1]) // Parse next arg
            if !ok do invalid(err_message) // Next arg must be integer
            config.n = n

        case "-m", "--method":
            err_message := "Must provide a valid method name following -m or --method."
            if len(os.args) == i + 1 do invalid(err_message) // Check for next arg
            valid := false
            for m in METHODS { // Search and match next arg in METHODS, case insensitive
                if strings.to_lower(os.args[i + 1]) == strings.to_lower(m.name) {
                    config.method = m
                    valid = true
                }
            }
            // Next arg must be a valid method in METHODS
            if !valid do invalid(err_message)

        case "-o", "--output":
            err_message := "Must provide a file path following -o or --output"
            if len(os.args) == i + 1 do invalid(err_message) // Check for next arg
            config.output = os.args[i + 1] // Next arg is taken at face value
            
        case "-p", "--profile":
            config.profile = true // Simple boolean argument
        }
    }
    
    return config
}

// Writes a slice of integers to file, newline-separated
write_primes_to_file :: proc(filename: string, primes: []int) {
    // Open and defer closing of file
    file, err := os.open(filename, os.O_WRONLY | os.O_CREATE | os.O_TRUNC, 0o644)
    defer os.close(file)
    
    // Write slice values to file, newline-separated
    if err != nil do fmt.printfln("ERROR: %s", err)
    for p in primes {
        fmt.fprintfln(file, "%i", p)
    }
}

// Runs the passed procedure and tracks time elapsed and memory usage.
// Compatible only with procedures of signature: (int) -> []int.
profile_proc :: proc(proc_to_profile: proc(int) -> []int, n: int, label: string = "Unnamed") -> []int {
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
    fmt.printfln("Maximum: %d", n)
    fmt.printfln("Memory allocation =====")
    fmt.printfln("Peak:    %v bytes", mem_tracker.peak_memory_allocated)
    fmt.printfln("Total:   %v bytes", mem_tracker.total_memory_allocated)

    return primes[:]
}
