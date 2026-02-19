package primes
//bitpack.odin - Experimental

// Storage format for large sets of prime numbers; bit-packed boolean array.
// 1 = true = prime; 0 = false = composite.
// Each bit corresponds to an integer k = 2(i + o) + 3 where i is the bit's index and o is the offset.
// The offset is the number of leading bits that have been truncated;
// An offset of 0 means bit 0 corresponds to the number 3, bit 1 to the number 5, bit 2 to 7, etc.
PrimeBits :: struct {
    data: [dynamic]u8,
    offset: u64,
}

// Splits a bit index into a byte index and a subindex.
split_index :: proc(bit_index: u64) -> (byte_i: u64, sub_i: u8) {
    byte_i = bit_index >> 3     // index / 8 == index >> 3 - index of relevant byte in array
    sub_i  = u8(bit_index & 7)  // index % 8 == index & 7  - index of bit within relevant byte
    return byte_i, sub_i
}

// Reads a single bit from a bit array.
// Returns an 8-bit boolean value equivalent to the bit's state; 1 = true; 0 = false
read_bit :: proc(bit_index: u64, bits: []u8) -> (bit_state: b8) #no_bounds_check {
    byte_i, sub_i := split_index(bit_index)  // Get split indices
    _byte: u8 = bits[byte_i]  // read relevant byte from array
    mask:  u8 = 1 << sub_i    // mask for which bit to read

    bit := _byte & mask       // Apply mask
    return bit != 0           // Expand to boolean
}

// Writes a single bit to a bit array.
// Takes an 8-bit boolean value equivalent to the bit's state; 1 = true; 0 = false
set_bit :: proc(bit_index: u64, set_to: b8, bits: []u8) #no_bounds_check {
    byte_i, sub_i := split_index(bit_index)  // Get split indices
    _byte: u8 = bits[byte_i]    // read relevant symbol from array
    mask:  u8 = 1 << sub_i      // mask for which bit to set

    _byte &= ~mask              // Set designated bit to 0
    if set_to do _byte |= mask  // Set designated bit to 1
    bits[byte_i] = _byte        // Write symbol back to array
}

pack_primes :: proc(primes: []u64) -> (primebits: PrimeBits) {
    primebits.data = make([dynamic]u8, 1, 8)
    for p in primes {
        if !has_bit_for(p, &primebits) do append(&primebits.data, 0)
        set_bit_for(p, true, &primebits)
    }
    return
}

unpack_primes :: proc(primebits: ^PrimeBits) -> (primes: [dynamic]u64) {
    primes = make([dynamic]u64, 0, 8)
    append(&primes, 2)
    for bit_index in 0..=len(primebits.data) * 8 {
        if read_bit(u64(bit_index), primebits.data[:]) {
            p := integer_at_bit(u64(bit_index), primebits)
            append(&primes, p)
        }
    }
    return primes
}


// Converts an index of a bit array to a u64 integer.
// Follows the k = 2(i + o) + 3 specification for PrimeBits.
integer_at_bit :: proc(bit_index: u64, primes: ^PrimeBits) -> (k: u64) {
    return 2 * (bit_index + primes.offset) + 3
}

// Converts a u64 integer into an index of a bit array.
// Follows the k = 2(i + o) + 3 specification for PrimeBits.
bit_index_for :: proc(k: u64, primes: ^PrimeBits) -> (bit_index: u64) {
    return ((k - 3) / 2) - primes.offset
}



// Gets the stored single-bit boolean for a given integer in a bit array
// Combination of bit_index_of() and read_bit()
read_bit_for :: proc(k: u64, primes: ^PrimeBits) -> (bit_state: b8) {
    return read_bit(bit_index_for(k, primes), primes.data[:])
}

// Stores a single-bit boolean for a given integer in a bit array
// Combination of bit_index_of() and set_bit()
set_bit_for :: proc(k: u64, set_to: b8, primes: ^PrimeBits) {
    set_bit(bit_index_for(k, primes), set_to, primes.data[:])
}



// Checks if a PrimeBits has allocated a bit for a given u64 integer
has_bit_for :: proc(k: u64, primes: ^PrimeBits) -> bool {
    return has_bit_index(bit_index_for(k, primes), primes.data[:])
}

// Checks if a bit array has grown to include a given bit index
has_bit_index :: proc(bit_index: u64, bits: []u8) -> bool {
    return bit_index < u64(len(bits)) * 8
}