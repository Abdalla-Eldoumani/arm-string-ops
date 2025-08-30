.text
.align 4

// ARMv8 NEON-Accelerated Case Conversion Operations
// High-performance ASCII case conversion using SIMD instructions

// Function: neon_to_upper
// Convert ASCII characters to uppercase in-place
// Parameters: x0 = str (char*), x1 = len (size_t)
// Register usage: x0-x4 = temp, v0-v4,v16-v18 = NEON vectors
.global neon_to_upper
.type neon_to_upper, %function
neon_to_upper:
    cbz     x1, .Lupper_ret     // Return if len == 0
    cbz     x0, .Lupper_ret     // Return if str == NULL
    
    mov     x2, x0              // Save original string pointer
    add     x3, x0, x1          // End pointer
    
    // Constants for ASCII lowercase detection and conversion
    movi    v16.16b, #'a'       // Lowercase 'a'
    movi    v17.16b, #'z'       // Lowercase 'z'
    movi    v18.16b, #32        // Difference between upper/lower case

    // Handle unaligned head bytes
    ands    x4, x0, #15
    beq     .Lupper_aligned     // Already aligned
    
.Lupper_head:  // Scalar processing for head alignment
    ldrb    w5, [x0]
    cmp     w5, #'a'
    blt     .Lupper_head_skip
    cmp     w5, #'z'
    bgt     .Lupper_head_skip
    sub     w5, w5, #32         // Convert to uppercase
    strb    w5, [x0]
.Lupper_head_skip:
    add     x0, x0, #1
    cmp     x0, x3
    beq     .Lupper_ret
    tst     x0, #15
    bne     .Lupper_head

.Lupper_aligned:  // Process 16-byte aligned chunks with NEON
    add     x4, x0, #15
    cmp     x4, x3
    bgt     .Lupper_tail        // Jump to tail processing
    
.Lupper_loop:  // Main NEON loop - process 16 bytes at a time
    ld1     {v0.16b}, [x0]      // Load 16 bytes
    
    // Check if bytes are lowercase letters (a-z)
    cmge    v1.16b, v0.16b, v16.16b  // >= 'a'
    cmge    v2.16b, v17.16b, v0.16b  // <= 'z'
    and     v3.16b, v1.16b, v2.16b   // Both conditions true
    
    // Convert to uppercase: subtract 32 where mask is true
    and     v4.16b, v18.16b, v3.16b  // Apply mask to conversion constant
    sub     v0.16b, v0.16b, v4.16b   // Conditional subtraction
    
    st1     {v0.16b}, [x0]      // Store result
    add     x0, x0, #16
    add     x4, x0, #15
    cmp     x4, x3
    ble     .Lupper_loop

.Lupper_tail:  // Process remaining tail bytes scalar
    cmp     x0, x3
    beq     .Lupper_ret
.Lupper_tail_loop:
    ldrb    w5, [x0]
    cmp     w5, #'a'
    blt     .Lupper_tail_skip
    cmp     w5, #'z'
    bgt     .Lupper_tail_skip
    sub     w5, w5, #32
    strb    w5, [x0]
.Lupper_tail_skip:
    add     x0, x0, #1
    cmp     x0, x3
    bne     .Lupper_tail_loop
    
.Lupper_ret:
    ret
.size neon_to_upper, . - neon_to_upper

// Function: neon_to_lower
// Convert ASCII characters to lowercase in-place
// Parameters: x0 = str (char*), x1 = len (size_t)
// Register usage: x0-x4 = temp, v0-v4,v16-v18 = NEON vectors
.global neon_to_lower
.type neon_to_lower, %function
neon_to_lower:
    cbz     x1, .Llower_ret     // Return if len == 0
    cbz     x0, .Llower_ret     // Return if str == NULL
    
    mov     x2, x0              // Save original string pointer
    add     x3, x0, x1          // End pointer
    
    // Constants for ASCII uppercase detection and conversion
    movi    v16.16b, #'A'       // Uppercase 'A'
    movi    v17.16b, #'Z'       // Uppercase 'Z'
    movi    v18.16b, #32        // Difference between upper/lower case

    // Handle unaligned head bytes
    ands    x4, x0, #15
    beq     .Llower_aligned     // Already aligned
    
.Llower_head:  // Scalar processing for head alignment
    ldrb    w5, [x0]
    cmp     w5, #'A'
    blt     .Llower_head_skip
    cmp     w5, #'Z'
    bgt     .Llower_head_skip
    add     w5, w5, #32         // Convert to lowercase
    strb    w5, [x0]
.Llower_head_skip:
    add     x0, x0, #1
    cmp     x0, x3
    beq     .Llower_ret
    tst     x0, #15
    bne     .Llower_head

.Llower_aligned:  // Process 16-byte aligned chunks with NEON
    add     x4, x0, #15
    cmp     x4, x3
    bgt     .Llower_tail        // Jump to tail processing
    
.Llower_loop:  // Main NEON loop - process 16 bytes at a time
    ld1     {v0.16b}, [x0]      // Load 16 bytes
    
    // Check if bytes are uppercase letters (A-Z)
    cmge    v1.16b, v0.16b, v16.16b  // >= 'A'
    cmge    v2.16b, v17.16b, v0.16b  // <= 'Z'
    and     v3.16b, v1.16b, v2.16b   // Both conditions true
    
    // Convert to lowercase: add 32 where mask is true
    and     v4.16b, v18.16b, v3.16b  // Apply mask to conversion constant
    add     v0.16b, v0.16b, v4.16b   // Conditional addition
    
    st1     {v0.16b}, [x0]      // Store result
    add     x0, x0, #16
    add     x4, x0, #15
    cmp     x4, x3
    ble     .Llower_loop

.Llower_tail:  // Process remaining tail bytes scalar
    cmp     x0, x3
    beq     .Llower_ret
.Llower_tail_loop:
    ldrb    w5, [x0]
    cmp     w5, #'A'
    blt     .Llower_tail_skip
    cmp     w5, #'Z'
    bgt     .Llower_tail_skip
    add     w5, w5, #32
    strb    w5, [x0]
.Llower_tail_skip:
    add     x0, x0, #1
    cmp     x0, x3
    bne     .Llower_tail_loop
    
.Llower_ret:
    ret
.size neon_to_lower, . - neon_to_lower