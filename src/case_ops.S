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
    cbz     x1, 9f              // Return if len == 0
    cbz     x0, 9f              // Return if str == NULL
    
    mov     x2, x0              // Save original string pointer
    add     x3, x0, x1          // End pointer
    
    // Constants for ASCII lowercase detection and conversion
    movi    v16.16b, #'a'       // Lowercase 'a'
    movi    v17.16b, #'z'       // Lowercase 'z'
    movi    v18.16b, #32        // Difference between upper/lower case

    // Handle unaligned head bytes
    ands    x4, x0, #15
    beq     2f                  // Already aligned
    
1:  // Scalar processing for head alignment
    ldrb    w5, [x0]
    cmp     w5, #'a'
    blt     1f
    cmp     w5, #'z'
    bgt     1f
    sub     w5, w5, #32         // Convert to uppercase
    strb    w5, [x0]
1:  add     x0, x0, #1
    cmp     x0, x3
    beq     9f
    tst     x0, #15
    bne     1b

2:  // Process 16-byte aligned chunks with NEON
    add     x4, x0, #15
    cmp     x4, x3
    bgt     8f                  // Jump to tail processing
    
3:  // Main NEON loop - process 16 bytes at a time
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
    ble     3b

8:  // Process remaining tail bytes scalar
    cmp     x0, x3
    beq     9f
8:  ldrb    w5, [x0]
    cmp     w5, #'a'
    blt     8f
    cmp     w5, #'z'
    bgt     8f
    sub     w5, w5, #32
    strb    w5, [x0]
8:  add     x0, x0, #1
    cmp     x0, x3
    bne     8b
    
9:  ret
.size neon_to_upper, . - neon_to_upper

// Function: neon_to_lower
// Convert ASCII characters to lowercase in-place
// Parameters: x0 = str (char*), x1 = len (size_t)
// Register usage: x0-x4 = temp, v0-v4,v16-v18 = NEON vectors
.global neon_to_lower
.type neon_to_lower, %function
neon_to_lower:
    cbz     x1, 9f              // Return if len == 0
    cbz     x0, 9f              // Return if str == NULL
    
    mov     x2, x0              // Save original string pointer
    add     x3, x0, x1          // End pointer
    
    // Constants for ASCII uppercase detection and conversion
    movi    v16.16b, #'A'       // Uppercase 'A'
    movi    v17.16b, #'Z'       // Uppercase 'Z'
    movi    v18.16b, #32        // Difference between upper/lower case

    // Handle unaligned head bytes
    ands    x4, x0, #15
    beq     2f                  // Already aligned
    
1:  // Scalar processing for head alignment
    ldrb    w5, [x0]
    cmp     w5, #'A'
    blt     1f
    cmp     w5, #'Z'
    bgt     1f
    add     w5, w5, #32         // Convert to lowercase
    strb    w5, [x0]
1:  add     x0, x0, #1
    cmp     x0, x3
    beq     9f
    tst     x0, #15
    bne     1b

2:  // Process 16-byte aligned chunks with NEON
    add     x4, x0, #15
    cmp     x4, x3
    bgt     8f                  // Jump to tail processing
    
3:  // Main NEON loop - process 16 bytes at a time
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
    ble     3b

8:  // Process remaining tail bytes scalar
    cmp     x0, x3
    beq     9f
8:  ldrb    w5, [x0]
    cmp     w5, #'A'
    blt     8f
    cmp     w5, #'Z'
    bgt     8f
    add     w5, w5, #32
    strb    w5, [x0]
8:  add     x0, x0, #1
    cmp     x0, x3
    bne     8b
    
9:  ret
.size neon_to_lower, . - neon_to_lower