// pbits.odin - Interface for storing generated primes in a bit array
package primes

import ba "core:container/bit_array"

// Storage format for large sets of prime numbers; bit-packed boolean array
// 
// `1 = true = prime; 0 = false = composite`
// 
// Each bit corresponds to a candidate odd integer `c = 2i + 3`
// where `i` is the bit's overall index.
PrimalityBitArray :: distinct ba.Bit_Array

// Iterator for a PrimalityBitArray.
PrimalityIterator :: distinct ba.Bit_Array_Iterator



// Creates a PrimalityBitArray
// 
// *Wrapper for `bit_array.create`*
create_pbits :: proc(max_index: int, min_index: int = 0, allocator := context.allocator) ->
                    (pbits: ^PrimalityBitArray, ok: bool) #optional_ok {
    bits: ^ba.Bit_Array
    bits, ok = ba.create(max_index, min_index, allocator)
    if ok do pbits = cast(^PrimalityBitArray)bits
    return pbits, ok
}

// Deallocates a PrimalityBitArray and its backing storage
// 
// *Wrapper for `bit_array.destroy`*
destroy_pbits :: proc(pbits: ^PrimalityBitArray) {
    ba.destroy(cast(^ba.Bit_Array)pbits)
}

// Initializes a PrimalityBitArray
// 
// *Wrapper for `bit_array.init`*
init_pbits :: proc(pbits: ^PrimalityBitArray, max_index: int, min_index: int = 0,
                   allocator := context.allocator) -> (ok: bool) {
    return ba.init(cast(^ba.Bit_Array)pbits, max_index, min_index, allocator)
}

// Sets all values in a PrimalityBitArray to `0 == false` by default,
// can also set them all to `1 == true` if specified
// 
// *Wrapper for `bit_array.clear`*
clear_pbits :: proc(pbits: ^PrimalityBitArray, clear_to: bool = false) {
    if !clear_to do ba.clear(cast(^ba.Bit_Array)pbits)
    else {
        for i in 0..=pbits.length {
            ok := set_pbit(pbits, i)
            if !ok do return
        }
    }
}

// Shrinks a PrimalityBitArray's backing storage to the smallest possible size
// 
// *Wrapper for `bit_array.shrink`*
shrink_pbits :: proc(pbits: ^PrimalityBitArray) { 
    ba.shrink(cast(^ba.Bit_Array)pbits)
}

// Gets the length of a PrimalityBitArray
// 
// *Wrapper for `bit_array.len`*
len_pbits :: proc(pbits: ^PrimalityBitArray) -> (length: int) {
    return ba.len(cast(^ba.Bit_Array)pbits)
}

// Gets the state of a single bit in a PrimalityBitArray
// 
// *Wrapper for `bit_array.get`*
get_pbit :: #force_inline proc(pbits: ^PrimalityBitArray, index: u64) -> (res: bool, ok: bool) #optional_ok {
    return ba.get(cast(^ba.Bit_Array)pbits, index)
}

// Sets the state of a single bit in a PrimalityBitArray (sets to true by default)
// 
// Conditionally Allocates (Resizes backing data when index > len(ba.bits))
// 
// *Wrapper for `bit_array.set`*
set_pbit :: #force_inline proc(pbits: ^PrimalityBitArray, #any_int index: uint, set_to: bool = true,
                               allocator := context.allocator) -> (ok: bool) {
    return ba.set(cast(^ba.Bit_Array)pbits, index, set_to, allocator)
}

// Sets the state of a single bit in a PrimalityBitArray to false
// 
// Conditionally Allocates (Resizes backing data when index > len(ba.bits))
// 
// *Wrapper for `bit_array.unset`*
unset_pbit :: #force_inline proc(pbits: ^PrimalityBitArray, #any_int index: uint,
                   allocator := context.allocator) -> (ok: bool) {
    return ba.unset(cast(^ba.Bit_Array)pbits, index, allocator)
}

// Gets the state of a single bit in a PrimalityBitArray
// 
// Bypasses all checks; does not allocate
// 
// *Wrapper for `bit_array.unsafe_get`*
unsafe_get_pbit :: #force_inline proc(pbits: ^PrimalityBitArray, #any_int index: uint) -> bool {
    return ba.unsafe_get(cast(^ba.Bit_Array)pbits, index)
}

// Sets the state a PrimalityBitArray to true
// 
// Bypasses all checks; does not allocate
// 
// *Wrapper for `bit_array.unsafe_set`*
unsafe_set_pbit :: #force_inline proc(pbits: ^PrimalityBitArray, bit: int) {
    ba.unsafe_set(cast(^ba.Bit_Array)pbits, bit)
}

// Sets the state a PrimalityBitArray to false
//
// Bypasses all checks; does not allocate
//
// *Wrapper for `bit_array.unsafe_unset`*
unsafe_unset_pbit :: #force_inline proc(pbits: ^PrimalityBitArray, bit: int) {
    ba.unsafe_unset(cast(^ba.Bit_Array)pbits, bit)
}

// Wraps a PrimalityBitArray into an iterator
//
// *Wrapper for `bit_array.make_iterator`*
make_piterator :: #force_inline proc(pbits: ^PrimalityBitArray) -> (piter: PrimalityIterator) {
    return cast(PrimalityIterator)ba.make_iterator(cast(^ba.Bit_Array)pbits)
}

// Returns the next bit, including its set-state. ok=false once exhausted
// 
// *Wrapper for `bit_array.iterate_by_all`*
iterate_all_pbits :: #force_inline proc(piter: ^PrimalityIterator) -> (set: bool, index: u64, ok: bool) {
    idx: int; set, idx, ok = ba.iterate_by_all(cast(^ba.Bit_Array_Iterator)piter)
    return set, u64(idx), ok
}

// Returns the next 'set' bit (bit with value 1 = true)
//
// *Wrapper for `bit_array.iterate_by_set`*
iterate_set_pbits :: #force_inline proc(piter: ^PrimalityIterator) -> (index: u64, ok: bool) {
    idx: int; idx, ok = ba.iterate_by_set(cast(^ba.Bit_Array_Iterator)piter)
    return u64(idx), ok
}

// Returns the next 'unset' bit (bit with value 0 = false)
//
// *Wrapper for `bit_array.iterate_by_unset`*
iterate_unset_pbits :: #force_inline proc(piter: ^PrimalityIterator) -> (index: u64, ok: bool) {
    idx: int; idx, ok = ba.iterate_by_unset(cast(^ba.Bit_Array_Iterator)piter)
    return u64(idx), ok
}



// Converts a PrimalityBitArray index into a candidate integer
candidate_at :: #force_inline proc(index: u64) -> (candidate: u64) {
    return 2 * index + 3
}

// Converts a candidate integer into an PrimalityBitArray index
bit_index_for :: #force_inline proc(candidate: u64) -> (index: u64) {
    return (candidate - 3) / 2
}

// Gets the state of the bit in a PrimalityBitArray that corresponds to a given candidate
get_pbit_for :: #force_inline proc(pbits: ^PrimalityBitArray, cdt: u64) -> (res: bool, ok: bool) #optional_ok {
    return get_pbit(pbits, bit_index_for(cdt))
}

// Sets the state of the bit in a PrimalityBitArray that corresponds to a given candidate
// (sets to true by default)
set_pbit_for :: #force_inline proc(pbits: ^PrimalityBitArray, cdt: u64, set_to: bool = true,
                                   allocator := context.allocator) ->(ok: bool) {
    return set_pbit(pbits, bit_index_for(cdt), set_to, allocator)
}

// Unsets the bit in a PrimalityBitArray that corresponds to a given candidate
// (sets to false)
unset_pbit_for :: #force_inline proc(pbits: ^PrimalityBitArray, cdt: u64, allocator := context.allocator) -> (ok: bool) {
    return unset_pbit(pbits, bit_index_for(cdt), allocator)
}

// Counts how many bits in a PrimalityBitArray are set to `1 == true`
count_set_bits :: proc(pbits: ^PrimalityBitArray) -> (count: u64) {
    piter := make_piterator(pbits)
    count = 0
    for {
        _, ok := next_set_candidate(&piter)
        if !ok do break  // ok will go false when end of array is reached
        count += 1
    }
    return count
}



// Returns the next candidate, including its bit's set-state
next_candidate :: #force_inline proc(piter: ^PrimalityIterator) -> (cdt: u64, bit_state: bool, ok:bool) {
    index: u64; bit_state, index, ok = iterate_all_pbits(piter)
    return candidate_at(index), bit_state, ok
}

// Returns the next candidate whose bit is set to `1 == true`
next_set_candidate :: #force_inline proc(piter: ^PrimalityIterator) -> (cdt: u64, ok:bool) {
    index: u64; index, ok = iterate_set_pbits(piter)
    return candidate_at(index), ok
}

// Returns the next candidate whose bit is unset to `0 == false`
next_unset_candidate :: #force_inline proc(piter: ^PrimalityIterator) -> (cdt: u64, ok:bool) {
    index: u64; index, ok = iterate_unset_pbits(piter)
    return candidate_at(index), ok
}



// Packs a slice of candidates into a PrimalityBitArray
//
// Iff a candidate is present in the slice, its bit will be set to `1 == true`
pack_candidates :: proc(pbits: ^PrimalityBitArray, candidates: []u64, allocator := context.allocator) -> (ok: bool) {
    // For each candidate present in the slice, set its bit to `1 == true`
    for c in candidates { 
        if c < 3 do continue // Must not pass 2 to set_pbit_for
        ok = set_pbit_for(pbits, c, true, allocator)
        if !ok do return false
    }
    
    return true
}

// Packs a slice of candidates into a PrimalityBitArray
//
// A candidate will only be added to the list if its bit is set to `1 == true`
unpack_candidates :: proc(pbits: ^PrimalityBitArray) -> (candidates: [dynamic]u64) {
    // Needs a dynamic array and bit array iterator
    candidates = make([dynamic]u64, 0, 8)
    piter := make_piterator(pbits)

    // Start with 2, all others are odd
    append(&candidates, 2)

    // Iterate through entire bit array and append all set candidates to dynamic array
    for {
        c, ok := next_set_candidate(&piter)  // Get next candidate whose bit is set to `1 == true`
        if !ok do break                      // `ok` will go false at end of bit array
        append(&candidates, c)               // Append candidate to dynamic array
    }

    return candidates
}

