.text
.align 4

// ARMv8 NEON-Accelerated UTF-8 Operations
// Fast UTF-8 validation and character counting using SIMD instructions

// Function: neon_utf8_validate
// Validate UTF-8 encoding using SIMD acceleration
// Parameters: x0 = str (const char*), x1 = len (size_t)
// Returns: w0 = 1 if valid UTF-8, 0 if invalid
.global neon_utf8_validate
.type neon_utf8_validate, %function
neon_utf8_validate:
    cbz     x1, 8f              // Empty string is valid
    cbz     x0, 9f              // NULL pointer is invalid
    
    add     x2, x0, x1          // End pointer
    
    // UTF-8 validation constants
    movi    v16.16b, #0x80      // 0b10000000 - continuation byte marker
    movi    v17.16b, #0xC0      // 0b11000000 - continuation byte mask

1:  // Main validation loop
    cmp     x0, x2
    bge     8f                  // End of string reached
    
    // Check if we have at least 16 bytes for SIMD processing
    add     x4, x0, #16
    cmp     x4, x2
    bgt     7f                  // Less than 16 bytes, use scalar
    
    // Load 16 bytes for SIMD processing
    ld1     {v0.16b}, [x0]
    
    // Fast path: check if all bytes are ASCII (< 0x80)
    cmgt    v1.16b, v16.16b, v0.16b  // Check if < 0x80 (ASCII)
    uminv   b25, v1.16b         // Get minimum (0 if any byte >= 0x80)
    fmov    w5, s25
    cmp     w5, #0
    beq     2f                  // Found non-ASCII, need careful validation
    
    // All ASCII - advance by 16 bytes
    add     x0, x0, #16
    b       1b
    
2:  // Non-ASCII found - validate each byte carefully (scalar fallback)
    mov     x5, #0              // Byte index within chunk
    
3:  // Validate individual bytes in the 16-byte chunk
    cmp     x5, #16
    beq     6f                  // Processed all 16 bytes
    
    ldrb    w6, [x0, x5]        // Load current byte
    
    // Check if ASCII
    cmp     w6, #0x80
    blt     5f                  // ASCII byte, continue
    
    // Non-ASCII byte - basic multi-byte validation
    cmp     w6, #0xC2
    blt     9f                  // Invalid (0x80-0xC1)
    cmp     w6, #0xF4
    bgt     9f                  // Invalid (> 0xF4)
    
    // Count expected continuation bytes
    mov     w7, #1              // At least 1 continuation
    cmp     w6, #0xE0
    blt     4f                  // 2-byte sequence
    add     w7, w7, #1          // 3-byte sequence
    cmp     w6, #0xF0
    blt     4f                  
    add     w7, w7, #1          // 4-byte sequence
    
4:  // Validate continuation bytes
    cbz     w7, 5f              // No more continuations needed
    add     x5, x5, #1          // Next byte
    cmp     x5, #16
    bge     9f                  // Incomplete sequence in chunk
    ldrb    w8, [x0, x5]
    and     w9, w8, #0xC0
    cmp     w9, #0x80
    bne     9f                  // Invalid continuation
    sub     w7, w7, #1
    b       4b
    
5:  // Continue to next byte
    add     x5, x5, #1
    b       3b
    
6:  // Finished processing 16-byte chunk
    add     x0, x0, #16
    b       1b
    
7:  // Scalar processing for remaining bytes
    cmp     x0, x2
    bge     8f
    ldrb    w6, [x0], #1
    
    // Simple scalar validation
    cmp     w6, #0x80
    blt     7b                  // ASCII
    
    // Basic multi-byte sequence validation
    cmp     w6, #0xC2
    blt     9f
    cmp     w6, #0xF4
    bgt     9f
    
    // Count expected continuation bytes
    mov     w7, #1              // At least 1 continuation
    cmp     w6, #0xE0
    blt     7f
    add     w7, w7, #1          // 2 continuations for 3-byte
    cmp     w6, #0xF0
    blt     7f
    add     w7, w7, #1          // 3 continuations for 4-byte
    
7:  // Validate continuation bytes
    cbz     w7, 7b              // No more continuations needed
    cmp     x0, x2
    bge     9f                  // Incomplete sequence
    ldrb    w8, [x0], #1
    and     w9, w8, #0xC0
    cmp     w9, #0x80
    bne     9f                  // Invalid continuation
    sub     w7, w7, #1
    b       7b
    
8:  // Valid UTF-8
    mov     w0, #1
    ret
    
9:  // Invalid UTF-8
    mov     w0, #0
    ret
.size neon_utf8_validate, . - neon_utf8_validate

// Function: neon_utf8_count_chars
// Count UTF-8 characters (not bytes) using SIMD acceleration
// Parameters: x0 = str (const char*), x1 = len (size_t)
// Returns: x0 = Unicode character count
.global neon_utf8_count_chars
.type neon_utf8_count_chars, %function
neon_utf8_count_chars:
    cbz     x1, 8f              // Empty string has 0 characters
    cbz     x0, 8f              // NULL pointer has 0 characters
    
    add     x2, x0, x1          // End pointer
    mov     x3, #0              // Character count
    
    // UTF-8 character counting constants
    movi    v16.16b, #0x80      // 0b10000000 - continuation byte marker
    movi    v17.16b, #0xC0      // 0b11000000 - continuation byte mask
    movi    v31.16b, #1         // Count increment vector

1:  // Main counting loop
    cmp     x0, x2
    bge     8f                  // End of string reached
    
    // Check if we have at least 16 bytes for SIMD processing
    add     x4, x0, #16
    cmp     x4, x2
    bgt     7f                  // Less than 16 bytes, use scalar
    
    // Load 16 bytes for SIMD processing
    ld1     {v0.16b}, [x0]
    
    // Fast path: check if all bytes are ASCII (< 0x80)
    cmgt    v1.16b, v16.16b, v0.16b  // v1 = 0xFF for ASCII bytes
    uminv   b25, v1.16b         // Check if all are ASCII
    fmov    w5, s25
    cmp     w5, #0
    beq     2f                  // Found non-ASCII, count carefully
    
    // All ASCII - each byte is a character
    add     x3, x3, #16
    add     x0, x0, #16
    b       1b
    
2:  // Mixed ASCII/non-ASCII - count non-continuation bytes
    // A UTF-8 character starts with a byte that's NOT a continuation byte
    // Continuation bytes have pattern 10xxxxxx (0x80-0xBF)
    
    // Check which bytes are NOT continuation bytes
    and     v2.16b, v0.16b, v17.16b   // Mask with 0xC0
    cmeq    v3.16b, v2.16b, v16.16b   // Compare with 0x80
    mvn     v4.16b, v3.16b            // Invert to get non-continuation mask
    
    // Count non-continuation bytes (these are character starts)
    and     v5.16b, v31.16b, v4.16b   // Apply mask to count vector
    addv    b6, v5.16b               // Sum all lanes
    fmov    w6, s6                   // Move to general register
    add     x3, x3, x6               // Add to total count
    
    add     x0, x0, #16
    b       1b
    
7:  // Scalar processing for remaining bytes
    cmp     x0, x2
    bge     8f
    ldrb    w5, [x0], #1
    
    // Count byte if it's not a continuation byte
    and     w6, w5, #0xC0
    cmp     w6, #0x80
    beq     7b                  // Skip continuation bytes
    add     x3, x3, #1          // Count character start
    b       7b
    
8:  // Return character count
    mov     x0, x3
    ret
.size neon_utf8_count_chars, . - neon_utf8_count_chars