#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <ctype.h>
#include "arm_string_ops.h"

// Simple timing function for QEMU
double get_time_seconds() {
    return (double)clock() / CLOCKS_PER_SEC;
}

// Standard library implementations for comparison
void std_to_upper(char* str, size_t len) {
    for (size_t i = 0; i < len; i++) {
        str[i] = toupper((unsigned char)str[i]);
    }
}

void std_to_lower(char* str, size_t len) {
    for (size_t i = 0; i < len; i++) {
        str[i] = tolower((unsigned char)str[i]);
    }
}

int std_utf8_validate_simple(const char* str, size_t len) {
    // Simple ASCII validation for comparison
    for (size_t i = 0; i < len; i++) {
        if ((unsigned char)str[i] > 127) return 0;
    }
    return 1;
}

size_t std_utf8_count_simple(const char* str, size_t len) {
    return len; // For ASCII, byte count = character count
}

// Benchmark a single operation
void benchmark_operation(const char* name, 
                        void (*neon_func)(char*, size_t), 
                        void (*std_func)(char*, size_t),
                        char* test_data, size_t data_size, int iterations) {
    
    printf("\n%s Benchmark (%zu bytes, %d iterations):\n", name, data_size, iterations);
    printf("----------------------------------------\n");
    
    // Benchmark NEON implementation
    char* work_buffer = malloc(data_size + 1);
    double neon_start = get_time_seconds();
    
    for (int i = 0; i < iterations; i++) {
        memcpy(work_buffer, test_data, data_size);
        work_buffer[data_size] = '\0';
        neon_func(work_buffer, data_size);
    }
    
    double neon_time = get_time_seconds() - neon_start;
    free(work_buffer);
    
    // Benchmark standard library
    work_buffer = malloc(data_size + 1);
    double std_start = get_time_seconds();
    
    for (int i = 0; i < iterations; i++) {
        memcpy(work_buffer, test_data, data_size);
        work_buffer[data_size] = '\0';
        std_func(work_buffer, data_size);
    }
    
    double std_time = get_time_seconds() - std_start;
    free(work_buffer);
    
    // Calculate metrics
    double neon_throughput = (data_size * iterations) / (neon_time * 1024.0 * 1024.0);
    double std_throughput = (data_size * iterations) / (std_time * 1024.0 * 1024.0);
    double speedup = std_time / neon_time;
    
    printf("NEON implementation: %.4f seconds (%.2f MB/s)\n", neon_time, neon_throughput);
    printf("Standard library:    %.4f seconds (%.2f MB/s)\n", std_time, std_throughput);
    printf("Speedup: %.2fx\n", speedup);
    
    if (speedup > 1.1) {
        printf("✓ NEON is faster\n");
    } else if (speedup > 0.9) {
        printf("≈ Performance is similar\n");
    } else {
        printf("✗ Standard library is faster (%.2fx)\n", 1.0/speedup);
    }
}

// Benchmark validation functions
void benchmark_validation(const char* name,
                         int (*neon_func)(const char*, size_t),
                         int (*std_func)(const char*, size_t),
                         const char* test_data, size_t data_size, int iterations) {
    
    printf("\n%s Benchmark (%zu bytes, %d iterations):\n", name, data_size, iterations);
    printf("----------------------------------------\n");
    
    // Benchmark NEON implementation
    double neon_start = get_time_seconds();
    volatile int neon_result;
    
    for (int i = 0; i < iterations; i++) {
        neon_result = neon_func(test_data, data_size);
    }
    
    double neon_time = get_time_seconds() - neon_start;
    
    // Benchmark standard library
    double std_start = get_time_seconds();
    volatile int std_result;
    
    for (int i = 0; i < iterations; i++) {
        std_result = std_func(test_data, data_size);
    }
    
    double std_time = get_time_seconds() - std_start;
    
    // Calculate metrics
    double neon_throughput = (data_size * iterations) / (neon_time * 1024.0 * 1024.0);
    double std_throughput = (data_size * iterations) / (std_time * 1024.0 * 1024.0);
    double speedup = std_time / neon_time;
    
    printf("NEON implementation: %.4f seconds (%.2f MB/s) [result=%d]\n", 
           neon_time, neon_throughput, neon_result);
    printf("Standard library:    %.4f seconds (%.2f MB/s) [result=%d]\n", 
           std_time, std_throughput, std_result);
    printf("Speedup: %.2fx\n", speedup);
    
    if (speedup > 1.1) {
        printf("✓ NEON is faster\n");
    } else if (speedup > 0.9) {
        printf("≈ Performance is similar\n");
    } else {
        printf("✗ Standard library is faster (%.2fx)\n", 1.0/speedup);
    }
}

// Benchmark counting functions
void benchmark_counting(const char* name,
                       size_t (*neon_func)(const char*, size_t),
                       size_t (*std_func)(const char*, size_t),
                       const char* test_data, size_t data_size, int iterations) {
    
    printf("\n%s Benchmark (%zu bytes, %d iterations):\n", name, data_size, iterations);
    printf("----------------------------------------\n");
    
    // Benchmark NEON implementation
    double neon_start = get_time_seconds();
    volatile size_t neon_result;
    
    for (int i = 0; i < iterations; i++) {
        neon_result = neon_func(test_data, data_size);
    }
    
    double neon_time = get_time_seconds() - neon_start;
    
    // Benchmark standard library
    double std_start = get_time_seconds();
    volatile size_t std_result;
    
    for (int i = 0; i < iterations; i++) {
        std_result = std_func(test_data, data_size);
    }
    
    double std_time = get_time_seconds() - std_start;
    
    // Calculate metrics
    double neon_throughput = (data_size * iterations) / (neon_time * 1024.0 * 1024.0);
    double std_throughput = (data_size * iterations) / (std_time * 1024.0 * 1024.0);
    double speedup = std_time / neon_time;
    
    printf("NEON implementation: %.4f seconds (%.2f MB/s) [count=%zu]\n", 
           neon_time, neon_throughput, neon_result);
    printf("Standard library:    %.4f seconds (%.2f MB/s) [count=%zu]\n", 
           std_time, std_throughput, std_result);
    printf("Speedup: %.2fx\n", speedup);
    
    if (speedup > 1.1) {
        printf("✓ NEON is faster\n");
    } else if (speedup > 0.9) {
        printf("≈ Performance is similar\n");
    } else {
        printf("✗ Standard library is faster (%.2fx)\n", 1.0/speedup);
    }
}

int main() {
    printf("QEMU-Optimized ARM String Operations Benchmark\n");
    printf("==============================================\n");
    printf("Optimized for QEMU user-mode emulation\n");
    
    // Test sizes optimized for QEMU (smaller sizes, fewer iterations)
    const size_t sizes[] = {1024, 8192, 32768};
    const size_t num_sizes = sizeof(sizes) / sizeof(sizes[0]);
    const int iterations = 100; // Reduced for QEMU
    
    for (size_t s = 0; s < num_sizes; s++) {
        size_t size = sizes[s];
        
        printf("\n");
        printf("=================================================\n");
        printf("Testing with %zu bytes\n", size);
        printf("=================================================\n");
        
        // Create test data - mixed case for case conversion
        char* mixed_data = malloc(size + 1);
        for (size_t i = 0; i < size; i++) {
            if (i % 2 == 0) {
                mixed_data[i] = 'A' + (i % 26);
            } else {
                mixed_data[i] = 'a' + (i % 26);
            }
        }
        mixed_data[size] = '\0';
        
        // Case conversion benchmarks
        benchmark_operation("Case Conversion (to_upper)", 
                          (void(*)(char*, size_t))neon_to_upper, 
                          std_to_upper,
                          mixed_data, size, iterations);
        
        benchmark_operation("Case Conversion (to_lower)", 
                          (void(*)(char*, size_t))neon_to_lower, 
                          std_to_lower,
                          mixed_data, size, iterations);
        
        // Create ASCII text for UTF-8 tests
        char* ascii_data = malloc(size + 1);
        const char* sample = "The quick brown fox jumps over the lazy dog. ";
        size_t sample_len = strlen(sample);
        
        for (size_t i = 0; i < size; i++) {
            ascii_data[i] = sample[i % sample_len];
        }
        ascii_data[size] = '\0';
        
        // UTF-8 validation benchmark
        benchmark_validation("UTF-8 Validation",
                           neon_utf8_validate,
                           std_utf8_validate_simple,
                           ascii_data, size, iterations);
        
        // UTF-8 character counting benchmark
        benchmark_counting("UTF-8 Character Counting",
                         neon_utf8_count_chars,
                         std_utf8_count_simple,
                         ascii_data, size, iterations);
        
        free(mixed_data);
        free(ascii_data);
    }
    
    printf("\n");
    printf("=================================================\n");
    printf("QEMU Benchmark Complete\n");
    printf("=================================================\n");
    printf("Note: These results are from QEMU emulation.\n");
    printf("Performance on native ARM hardware will be different.\n");
    printf("QEMU adds emulation overhead that affects all measurements.\n");
    
    return 0;
}