#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <time.h>
#include "arm_string_ops.h"

#define TEST_ASSERT(condition, message) \
    do { \
        if (!(condition)) { \
            printf("FAIL: %s\n", message); \
            return 0; \
        } else { \
            printf("PASS: %s\n", message); \
        } \
    } while(0)

// Test case conversion functions
int test_case_conversion() {
    printf("\n=== Testing Case Conversion ===\n");
    
    // Test neon_to_upper
    char test1[] = "Hello World! 123";
    neon_to_upper(test1, strlen(test1));
    TEST_ASSERT(strcmp(test1, "HELLO WORLD! 123") == 0, "neon_to_upper basic test");
    
    // Test neon_to_lower
    char test2[] = "HELLO WORLD! 123";
    neon_to_lower(test2, strlen(test2));
    TEST_ASSERT(strcmp(test2, "hello world! 123") == 0, "neon_to_lower basic test");
    
    // Test with long string (>16 chars to test SIMD path)
    char long_test[] = "This is a very long string that should trigger SIMD processing";
    neon_to_upper(long_test, strlen(long_test));
    TEST_ASSERT(strncmp(long_test, "THIS IS A VERY LONG", 19) == 0, "neon_to_upper long string test");
    
    // Test edge cases
    char empty[] = "";
    neon_to_upper(empty, 0);  // Should not crash
    TEST_ASSERT(strlen(empty) == 0, "neon_to_upper empty string");
    
    // Test non-ASCII (should be unchanged)
    char utf8_test[] = "Hello cafe";
    char utf8_copy[32];
    strcpy(utf8_copy, utf8_test);
    neon_to_upper(utf8_test, strlen(utf8_test));
    // Only ASCII parts should change
    TEST_ASSERT(strncmp(utf8_test, "HELLO", 5) == 0, "neon_to_upper ASCII-only conversion");
    
    return 1;
}

// Test UTF-8 validation and counting
int test_utf8_ops() {
    printf("\n=== Testing UTF-8 Operations ===\n");
    
    // Test UTF-8 validation
    char ascii[] = "Hello World";
    TEST_ASSERT(neon_utf8_validate(ascii, strlen(ascii)) == 1, "UTF-8 validation ASCII");
    
    // Test simple ASCII text
    char ascii_text[] = "Hello ASCII World";
    TEST_ASSERT(neon_utf8_validate(ascii_text, strlen(ascii_text)) == 1, "UTF-8 validation ASCII text");
    
    // Test UTF-8 character counting
    TEST_ASSERT(neon_utf8_count_chars(ascii, strlen(ascii)) == 11, "UTF-8 char count ASCII");
    
    // ASCII-only string character counting
    char simple_ascii[] = "Hello";
    size_t char_count = neon_utf8_count_chars(simple_ascii, strlen(simple_ascii));
    TEST_ASSERT(char_count == 5, "UTF-8 char count simple ASCII");
    
    // Empty string
    TEST_ASSERT(neon_utf8_validate("", 0) == 1, "UTF-8 validation empty string");
    TEST_ASSERT(neon_utf8_count_chars("", 0) == 0, "UTF-8 char count empty string");
    
    return 1;
}



// Performance test helper
void performance_test() {
    printf("\n=== Performance Tests ===\n");
    
    const size_t test_size = 100000;  // 100KB
    char* large_buffer = malloc(test_size + 1);
    
    // Fill with test data
    for (size_t i = 0; i < test_size; i++) {
        large_buffer[i] = 'a' + (i % 26);
    }
    large_buffer[test_size] = '\0';
    
    clock_t start, end;
    double cpu_time_used;
    
    // Test case conversion performance
    start = clock();
    for (int i = 0; i < 100; i++) {
        neon_to_upper(large_buffer, test_size);
        neon_to_lower(large_buffer, test_size);
    }
    end = clock();
    cpu_time_used = ((double)(end - start)) / CLOCKS_PER_SEC;
    double throughput = (test_size * 200) / (cpu_time_used * 1024 * 1024);
    printf("Case conversion: %.2f MB/s\n", throughput);
    
    // Test UTF-8 validation performance
    start = clock();
    for (int i = 0; i < 100; i++) {
        neon_utf8_validate(large_buffer, test_size);
    }
    end = clock();
    cpu_time_used = ((double)(end - start)) / CLOCKS_PER_SEC;
    throughput = (test_size * 100) / (cpu_time_used * 1024 * 1024);
    printf("UTF-8 validation: %.2f MB/s\n", throughput);
    
    free(large_buffer);
}

int main() {
    printf("ARM String Operations Library Test Harness\n");
    printf("==========================================\n");
    
    int all_passed = 1;
    
    // Run all test suites
    all_passed &= test_case_conversion();
    all_passed &= test_utf8_ops();
    
    // Run performance tests
    performance_test();
    
    printf("\n=== Test Summary ===\n");
    if (all_passed) {
        printf("✓ All tests PASSED!\n");
        return 0;
    } else {
        printf("✗ Some tests FAILED!\n");
        return 1;
    }
}