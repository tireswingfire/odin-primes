// wheel.odin - EXPERIMENTAL
package primes

import "core:fmt"

// A wheel describes a set of integers (residuals) not divisible by any of the first n primes (moduli).
//
// The intervals between residuals are periodic by the `product` (product of all moduli),
// so only the values for the first period are stored.
// Subsequent periods can be obtained by adding multiples of the `product`
Wheel :: struct {
    level: u64,
    moduli: [dynamic]u64,
    product: u64,
    residuals: [dynamic]u64,
    res_count: u64,
    free_pointer: bool,
}

// Creates a wheel for a given value n.
//
// The wheel will contain the first n primes, their product, and the first period of their residuals.
create_wheel :: proc(n: u64, allocator := context.allocator) -> (w: ^Wheel, ok: bool) #optional_ok {
    // Enforce a practical limit on n; should be <= 9 and must be <= 15
    // For n > 9, the array of residuals grows beyond 125 million entries or ~1GiB
    // For n > 15, the product of the first n primes grows beyond the u64 limit.
    if n > 9 do return nil, false
    
    // Allocate on heap
    w = new(Wheel)
    w.free_pointer = true

    // Keep track of n
    w.level = n

    // Make dynamic arrays
    w.moduli = make([dynamic]u64, 0)
    w.residuals = make([dynamic]u64, 0)

    // Generate moduli - first n prime numbers;
    // Slightly modified primes_tridiv_odds method;
    // First one is always 2, any others are odd.
    append(&w.moduli, 2)  
    for c: u64 = 3; u64(len(w.moduli)) < n; c += 2 {
        c_is_prime := true
        for m in w.moduli {
            if m * m > c do break
            if c % m == 0 {
                c_is_prime = false
                break
            } 
        }
        if c_is_prime do append(&w.moduli, c)
    }
    
    // Calculate the product of all moduli and 1
    w.product = 1
    for m in w.moduli do w.product *= m

    // Generate residuals - the first period of all integers coprime with the product.
    //
    // for n=0. product=1  and moduli={},        residuals will be {1}.
    // for n=1, product=2  and moduli={2},       residuals will be {1}.
    // for n=2, product=6  and moduli={2, 3},    residuals will be {1, 5}.
    // for n=3, product=30 and moduli={2, 3, 5}, residuals will be {1, 7, 11, 13, 17, 19, 23, 29}.
    //
    // Such that k will be the i'th number not divisible by any moduli (coprime with the product);
    // k = residuals[i % len(residuals)] + floor(i / len(residuals)) * product
    for c: u64 = 1; c <= w.product ; c += 2 {
        c_is_res := true
        for m in w.moduli {
            if c % m == 0 {
                c_is_res = false
                break
            } 
        }
        if c_is_res do append(&w.residuals, c)
    }

    // Count the number of residuals once for future repeated use
    w.res_count = u64(len(w.residuals))

    return w, true
}

// Destroys a wheel.
//
// *Deallocates `moduli` and `residuals`; frees the struct if it is on the heap.*
destroy_wheel :: proc(w: ^Wheel, allocator := context.allocator) {
    if w == nil do return
    delete(w.moduli)
    delete(w.residuals)
    // Only free if the wheel was created using `create_wheel` and is not on the stack.
    if w.free_pointer do free(w)
}



// Gets k, the i'th residual.
//
// Residuals are periodic by the `product`, so only the first period of `residuals` are stored.
// Subsequent periods can be obtained by adding integer multiples of the `product`.
wheel_residual_at :: proc(w: ^Wheel, index: u64) -> (res: u64) {
    return w.residuals[index % w.res_count] + (index / w.res_count) * w.product
}

// Gets the non-periodic index for an integer on a given wheel.
wheel_index_for :: proc(w: ^Wheel, integer: u64) -> (index: u64) {
    // Prevent u64 underflow
    if integer == 0 do return 0

    // Start with a period offset equal to some multiple of the product
    index = (integer / w.product) * w.res_count

    // Round down to the nearest residual
    remainder := integer % w.product
    for res, i in w.residuals {
        if remainder < res {
            index += u64(i - 1)
            break
        }
        if remainder == res {
            index += u64(i)
            break
        }
    }

    return index
}