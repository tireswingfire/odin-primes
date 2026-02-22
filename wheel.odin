// wheel.odin - EXPERIMENTAL
package primes

// A wheel describes a set of integers (residuals) not divisible by any in another set (moduli).
//
// The intervals between residuals are periodic by the `product` (product of all moduli),
// so only the values for the first period is stored.
// Subsequent periods can be obtained by adding multiples of `product`
Wheel :: struct {
    moduli: [dynamic]u64,
    product: u64,
    residuals: [dynamic]u64,
    free_pointer: bool,
}

// Destroys a wheel; deallocates the dynamic arrays and frees the struct if it is on the heap
destroy_wheel :: proc(w: ^Wheel, allocator := context.allocator) {
    if w == nil do return
    delete(w.moduli)
    delete(w.residuals)
    // Only free if the wheel was created using `create_wheel` and is not on the stack.
    if w.free_pointer do free(w)
}

// Creates a wheel for a given value n.
//
// The wheel will contain the first n primes, their product, and their non-periodic residuals.
create_wheel :: proc(n: u64, allocator := context.allocator) -> (w: ^Wheel, ok: bool) #optional_ok {
    // Enforce a limit on n; must be <= 15
    // For n > 15, the product of the first n primes grows beyond the u64 limit.
    //
    // n    product
    // 0	1
    // 1	2
    // 2	6
    // 3	30
    // 4    210
    // 5    2310
    // ...
    // 15	614889782588491410
    // u64  18446744073709551615 max
    // 16	32589158477190044730 (above u64 limit)
    if n > 15 do return nil, false
    
    // Allocate on heap
    w = new(Wheel)
    w.free_pointer = true

    // Make dynamic arrays
    w.moduli = make([dynamic]u64, 0)
    w.residuals = make([dynamic]u64, 0)

    // Explicit wheel 0
    if n == 0 {
        w.product = 0
        append(&w.residuals, 2)
        return w, true
    }

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
    
    // Calculate the product of all moduli
    w.product = 1
    for m in w.moduli do w.product *= m

    // Generate residuals - the first period of all integers coprime with the product.
    //
    // for n=1, product=2  and moduli={2},       residuals will be {3}.
    // for n=2, product=6  and moduli={2, 3},    residuals will be {5, 7}.
    // for n=3, product=30 and moduli={2, 3, 5}, residuals will be {7, 11, 13, 17, 19, 23, 29, 31}.
    //
    // Such that k will be the i'th number not divisible by any moduli (coprime with the product);
    // k = residuals[i % p] + floor(i / p) * p; where p is the product.
    for c: u64 = 3; c < w.product + 2 ; c += 2 {
        c_is_res := true
        for m in w.moduli {
            if c % m == 0 {
                c_is_res = false
                break
            } 
        }
        if c_is_res do append(&w.residuals, c)
    }

    return w, true
}
