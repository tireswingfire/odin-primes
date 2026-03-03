// piter.odin - Interator for a PrimalityBitArray and related procedures
package primes

import ba "core:container/bit_array"
import "core:fmt"

// Iterator for a PrimalityBitArray
PrimalityIterator :: distinct ba.Bit_Array_Iterator



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
