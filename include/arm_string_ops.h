#ifndef ARM_STRING_OPS_H
#define ARM_STRING_OPS_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// ARMv8 NEON-Accelerated String Operations Library
// High-performance string processing using SIMD instructions

// Case conversion operations (ASCII only, non-ASCII bytes unchanged)
// These functions modify the input string in-place for maximum performance
void neon_to_upper(char* str, size_t len);
void neon_to_lower(char* str, size_t len);

// UTF-8 operations  
// Fast validation and character counting with SIMD acceleration
int neon_utf8_validate(const char* str, size_t len);    // returns 1 if valid, 0 if invalid
size_t neon_utf8_count_chars(const char* str, size_t len);  // returns Unicode character count

#ifdef __cplusplus
}
#endif

#endif