// system.odin - Operating system and command line interactions.
package primes

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

// Help message to print when -h or --help argument is passed
print_help_message :: proc() {
    fmt.printfln("Usage:")
    fmt.printfln("\t-n --max <int> (default:%v)    \t| Generate primes up to this limit", default_cfg.n)
    fmt.printfln("\t-m --method <name> (default:%v)\t| Method/algorithm to use", default_cfg.method.name)
    fmt.printfln("\t\tMethods:")
    for m in METHODS do fmt.printfln("\t\t%s    \t| %s", m.name, m.description)
    fmt.printfln(" ")
    fmt.printfln("\t-p --profile (default:%v)      \t| Track time elapsed and memory usage", default_cfg.profiling)
    fmt.printfln("\t-o --output <path> (default:%v)\t| Output file to export to", default_cfg.output)
    fmt.printfln("\t-h --help | Show this help message")
}

// Parses command line arguments and populates a configuration struct accordingly
parse_clargs_config :: proc() -> (config: Config, ok: bool) {
    // Initialize config to default; return if no arguments were passed
    config = default_cfg
    if len(os.args) <= 1 do return config, true

    // Invalid argument messenger
    invalid :: proc(message: string) {
        fmt.eprintln("Invalid argument:", message)
        print_help_message()
    }

    // Safely gets the value for arguments that require one
    get_value_for :: proc(i: int) -> (value: string, ok: bool) {
        if i + 1 >= len(os.args) {
            invalid(fmt.tprintf("Missing value after %q", os.args[i]))
            return "", false
        }
        return os.args[i + 1], true
    }

    // Parse arguments starting at os:args[1], skip executable path at os:args[0]
    for i := 1; i < len(os.args); i += 1 {
        arg := os.args[i]

        switch arg {
        // Help argument
        case "-h", "--help":
            print_help_message()
            config.help = true
            return config, true // Return early

        // Profiling argument
        case "-p", "--profile":
            config.profiling = true

        // Upper limit argument
        case "-n", "--max":
            value := get_value_for(i) or_return // Get next arg if it exists
            n, ok := strconv.parse_u64(value) // Parse next arg
            if !ok { // Next arg must be integer
                invalid(fmt.tprintf("Invalid integer for -n / --max: %q", value))
                return {}, false
            }
            config.n = n
            i += 1 // Consume value and flag

        // Method selection argument
        case "-m", "--method":
            value := get_value_for(i) or_return // Get next arg if it exists
            found := false
            for m in METHODS { // Search and match next arg in METHODS, case insensitive
                if strings.equal_fold(value, m.name) {
                    config.method = m
                    found = true
                    break
                }
            }
            if !found { // Next arg must be a valid method name
                invalid(fmt.tprintf("Invalid method name for -m / --method: %q", value))
                return {}, false
            }
            i += 1 // Consume value and flag

        // Output file path argument
        case "-o", "--output":
            value := get_value_for(i) or_return // Get next arg if it exists
            config.output = value // Next arg is taken at face value
            i += 1 // Consume value and flag

        // Default case; unknown argument
        case:
            invalid(fmt.tprintf("Unknown argument %q", arg))
            return {}, false
        }
    }
    return config, true
}

// Writes numerical values for a bit array of primes to file, newline-separated
write_primes_to_file :: proc(pbits: ^PrimalityBitArray, filename: string) -> os.Error {
    // Open and defer closing of file; return upon error
    file, err := os.open(filename, os.O_WRONLY | os.O_CREATE | os.O_TRUNC, 0o644)
    if err != nil {
        fmt.eprintfln("Failed to open output file %q: %v", filename, err)
        return err
    }
    defer os.close(file)

    piter: PrimalityIterator = make_piterator(pbits)
    p: u64 = 2
    ok: bool = true
    // Iterate through the entire PrimalityBitsArray
    for {
        // Print the numerical value of each prime to file, starting with 2
        bytes_printed := fmt.fprintfln(file, "%d", p)
        if bytes_printed <= 0 {
            fmt.eprintfln("Write failed on prime %d", p)
            return os.ERROR_OPERATION_ABORTED
        }
        // Get next prime
        p, ok = next_set_candidate(&piter)
        // `ok` will be false when end of bit array is reached
        if !ok do break
    }
    
    return nil
}