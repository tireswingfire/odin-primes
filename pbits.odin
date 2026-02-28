// pbits.odin - Interface for storing generated primes in a bit array
package primes

import ba "core:container/bit_array"
import "core:fmt"

// Storage format for large sets of prime numbers;
// A paired pointer to a bit array and a wheel
// 
// The bits represent `1 = true = prime; 0 = false = composite`
// 
// The wheel determines which integers the bits in the array correspond to.
PrimalityBitArray :: struct {
    arr: ^ba.Bit_Array,
    wheel: ^Wheel,
    free_pointer: bool,
}

// Iterator for a PrimalityBitArray
PrimalityIterator :: distinct ba.Bit_Array_Iterator



// Creates a PrimalityBitArray
create_pbits :: proc(wheel_lvl: u64, c_max: u64, allocator := context.allocator) ->
                    (pbits: ^PrimalityBitArray, ok: bool) #optional_ok {
    // Allocate on heap
    pbits = new(PrimalityBitArray)
    pbits.free_pointer = true

    // Create wheel; return on failure
    pbits.wheel, ok = create_wheel(wheel_lvl)
    if !ok do return {}, false

    // Create bit array; return on failure
    i_max := wheel_index_for(pbits.wheel, c_max)
    when ODIN_DEBUG {
        fmt.eprintln("\ncreate_pbits: Creating PrimalityBitArray...")
        fmt.eprintln(wheel_lvl, c_max, c_min, i_max)
    }
    pbits.arr, ok = ba.create(int(i_max), 1, allocator)
    if !ok do return {}, false

    // Debug build info
    when ODIN_DEBUG {
        fmt.eprintln("\ncreate_pbits: Created PrimalityBitArray:")
        fmt.eprintln(pbits)
        fmt.eprintln(pbits.arr^)
        fmt.eprintln(pbits.wheel^)
    }

    return pbits, true
}

// Destroys a PrimalityBitArray
//
// Deallocates the bit array, the wheel, and their backing storage
destroy_pbits :: proc(pbits: ^PrimalityBitArray) {
    ba.destroy(pbits.arr)
    destroy_wheel(pbits.wheel)
    if pbits.free_pointer do free(pbits)
}

// Sets all values in the  to `0 == false` by default, or to `1 == true` if specified
// 
// *Extended wrapper for `bit_array.clear`*
clear_pbits :: proc(pbits: ^PrimalityBitArray, clear_to: bool = false) {
    if !clear_to do ba.clear(pbits.arr)
    else {
        for i in 0..=pbits.arr.length {
            ok := set_pbit(pbits, i)
            if !ok do return
        }
    }
    // First bit is for 1, which should always be unset.
    unset_pbit_for(pbits, 1)
}



// Converts a PrimalityBitArray index into a candidate integer according to the wheel's residuals
candidate_at :: #force_inline proc(pbits: ^PrimalityBitArray, index: u64) -> (candidate: u64) {
    return wheel_residual_at(pbits.wheel, index)
}

// Converts a candidate integer into an PrimalityBitArray index
bit_index_for :: #force_inline proc(pbits: ^PrimalityBitArray, candidate: u64) -> (index: u64) {
    return wheel_index_for(pbits.wheel, candidate)
}

// Gets the state of the bit in a PrimalityBitArray that corresponds to a given candidate
get_pbit_for :: #force_inline proc(pbits: ^PrimalityBitArray, cdt: u64) -> (res: bool, ok: bool) #optional_ok {
    return get_pbit(pbits, bit_index_for(pbits, cdt))
}

// Sets the state of the bit in a PrimalityBitArray that corresponds to a given candidate
// (sets to true by default)
set_pbit_for :: #force_inline proc(pbits: ^PrimalityBitArray, cdt: u64, set_to: bool = true,
                                   allocator := context.allocator) ->(ok: bool) {
    return set_pbit(pbits, bit_index_for(pbits, cdt), set_to, allocator)
}

// Unsets the bit in a PrimalityBitArray that corresponds to a given candidate
// (sets to false)
unset_pbit_for :: #force_inline proc(pbits: ^PrimalityBitArray, cdt: u64, allocator := context.allocator) -> (ok: bool) {
    return unset_pbit(pbits, bit_index_for(pbits, cdt), allocator)
}

// Counts how many bits in a PrimalityBitArray are set to `1 == true`
count_set_bits :: proc(pbits: ^PrimalityBitArray) -> (count: u64) {
    piter := make_piterator(pbits)
    count = 0
    for {
        _, ok := next_set_candidate(pbits, &piter)
        if !ok do break  // ok will go false when end of array is reached
        count += 1
    }
    return count
}



// Returns the next candidate, including its bit's set-state
next_candidate :: #force_inline proc(pbits: ^PrimalityBitArray, piter: ^PrimalityIterator) ->
                                    (cdt: u64, bit_state: bool, ok:bool) {
    index: u64
    bit_state, index, ok = iterate_all_pbits(piter)
    return candidate_at(pbits, index), bit_state, ok
}

// Returns the next candidate whose bit is set to `1 == true`
next_set_candidate :: #force_inline proc(pbits: ^PrimalityBitArray, piter: ^PrimalityIterator) ->
                                        (cdt: u64, ok:bool) {
    index: u64
    index, ok = iterate_set_pbits(piter)
    return candidate_at(pbits, index), ok
}

// Returns the next candidate whose bit is unset to `0 == false`
next_unset_candidate :: #force_inline proc(pbits: ^PrimalityBitArray, piter: ^PrimalityIterator) -> 
                                          (cdt: u64, ok:bool) {
    index: u64
    index, ok = iterate_unset_pbits(piter)
    return candidate_at(pbits, index), ok
}



// Packs a slice of candidates into a PrimalityBitArray
//
// Iff a candidate is present in the slice, its bit will be set to `1 == true`
pack_candidates :: proc(pbits: ^PrimalityBitArray, candidates: []u64, allocator := context.allocator) -> (ok: bool) {
    // For each candidate present in the slice, set its bit to `1 == true`
    for c in candidates { 
        ok = set_pbit_for(pbits, c, true, allocator)
        if !ok do return false
    }

    // Debug build info
    when ODIN_DEBUG {
        fmt.eprintln("\npack_candidates: Packed candidates.")
        fmt.eprintln("Candidates:", candidates)
        fmt.eprintln("Packed:", pbits.arr^)
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
        // Get next candidate whose bit is set to `1 == true`
        c, ok := next_set_candidate(pbits, &piter)  
        if !ok do break         // `ok` will go false at end of bit array
        append(&candidates, c)  // Append candidate to dynamic array
    }

    // Debug build info
    when ODIN_DEBUG {
        fmt.eprintln("\nunpack_candidates: Unpacked candidates.")
        fmt.eprintln("Bit Array:", pbits.arr^)
        fmt.eprintln("Unpacked:", candidates)
    }

    return candidates
}



// Initializes a PrimalityBitArray
// 
// *Wrapper for `bit_array.init`*
init_pbits :: proc(pbits: ^PrimalityBitArray, max_index: int, min_index: int = 0,
                   allocator := context.allocator) -> (ok: bool) {
    return ba.init(pbits.arr, max_index, min_index, allocator)
}

// Shrinks a PrimalityBitArray's backing storage to the smallest possible size
// 
// *Wrapper for `bit_array.shrink`*
shrink_pbits :: proc(pbits: ^PrimalityBitArray) { 
    ba.shrink(pbits.arr)
}

// Gets the length of a PrimalityBitArray
// 
// *Wrapper for `bit_array.len`*
len_pbits :: proc(pbits: ^PrimalityBitArray) -> (length: int) {
    return ba.len(pbits.arr)
}

// Gets the state of a single bit in a PrimalityBitArray
// 
// *Wrapper for `bit_array.get`*
get_pbit :: #force_inline proc(pbits: ^PrimalityBitArray, index: u64) -> (res: bool, ok: bool) #optional_ok {
    return ba.get(pbits.arr, index)
}

// Sets the state of a single bit in a PrimalityBitArray (sets to true by default)
// 
// Conditionally Allocates (Resizes backing data when index > len(ba.bits))
// 
// *Wrapper for `bit_array.set`*
set_pbit :: #force_inline proc(pbits: ^PrimalityBitArray, #any_int index: uint, set_to: bool = true,
                               allocator := context.allocator) -> (ok: bool) {
    return ba.set(pbits.arr, index, set_to, allocator)
}

// Sets the state of a single bit in a PrimalityBitArray to false
// 
// Conditionally Allocates (Resizes backing data when index > len(ba.bits))
// 
// *Wrapper for `bit_array.unset`*
unset_pbit :: #force_inline proc(pbits: ^PrimalityBitArray, #any_int index: uint,
                   allocator := context.allocator) -> (ok: bool) {
    return ba.unset(pbits.arr, index, allocator)
}

// Gets the state of a single bit in a PrimalityBitArray
// 
// Bypasses all checks; does not allocate
// 
// *Wrapper for `bit_array.unsafe_get`*
unsafe_get_pbit :: #force_inline proc(pbits: ^PrimalityBitArray, #any_int index: uint) -> bool {
    return ba.unsafe_get(pbits.arr, index)
}

// Sets the state a PrimalityBitArray to true
// 
// Bypasses all checks; does not allocate
// 
// *Wrapper for `bit_array.unsafe_set`*
unsafe_set_pbit :: #force_inline proc(pbits: ^PrimalityBitArray, bit: int) {
    ba.unsafe_set(pbits.arr, bit)
}

// Sets the state a PrimalityBitArray to false
//
// Bypasses all checks; does not allocate
//
// *Wrapper for `bit_array.unsafe_unset`*
unsafe_unset_pbit :: #force_inline proc(pbits: ^PrimalityBitArray, bit: int) {
    ba.unsafe_unset(pbits.arr, bit)
}



// Wraps a PrimalityBitArray into an iterator
//
// *Wrapper for `bit_array.make_iterator`*
make_piterator :: #force_inline proc(pbits: ^PrimalityBitArray) -> (piter: PrimalityIterator) {
    return cast(PrimalityIterator)ba.make_iterator(pbits.arr)
}

// Returns the next bit, including its set-state. ok=false once exhausted
// 
// *Wrapper for `bit_array.iterate_by_all`*
iterate_all_pbits :: #force_inline proc(piter: ^PrimalityIterator) -> (set: bool, index: u64, ok: bool) {
    idx: int
    set, idx, ok = ba.iterate_by_all(cast(^ba.Bit_Array_Iterator)piter)
    return set, u64(idx), ok
}

// Returns the next 'set' bit (bit with value 1 = true)
//
// *Wrapper for `bit_array.iterate_by_set`*
iterate_set_pbits :: #force_inline proc(piter: ^PrimalityIterator) -> (index: u64, ok: bool) {
    idx: int
    idx, ok = ba.iterate_by_set(cast(^ba.Bit_Array_Iterator)piter)
    return u64(idx), ok
}

// Returns the next 'unset' bit (bit with value 0 = false)
//
// *Wrapper for `bit_array.iterate_by_unset`*
iterate_unset_pbits :: #force_inline proc(piter: ^PrimalityIterator) -> (index: u64, ok: bool) {
    idx: int
    idx, ok = ba.iterate_by_unset(cast(^ba.Bit_Array_Iterator)piter)
    return u64(idx), ok
}
