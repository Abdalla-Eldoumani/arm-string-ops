#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/time.h>
#include <ctype.h>
#include "arm_string_ops.h"

// Timing utilities
double get_time() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec + tv.tv_usec / 1000000.0;
}

// Standard library implementations for comparison
void std_to_upper(char* str, size_t len) {
    for (size_t i = 0; i < len; i++) {
        str[i] = toupper(str[i]);
    }
}

void std_to_lower(char* str, size_t len) {
    for (size_t i = 0; i < len; i++) {
        str[i] = tolower(str[i]);
    }
}

int std_utf8_validate_simple(const char* str, size_t len) {
    // Simple ASCII-only validation for comparison
    for (size_t i = 0; i < len; i++) {
        if ((unsigned char)str[i] > 127) return 0;
    }
    return 1;
}

size_t std_utf8_count_simple(const char* str, size_t len) {
    // Simple byte counting for ASCII
    return len;
}

// Benchmark framework
typedef struct {
    const char* name;
    void (*setup)(char** data, size_t size);
    double (*benchmark_neon)(char* data, size_t size, int iterations);
    double (*benchmark_std)(char* data, size_t size, int iterations);
} benchmark_t;

// Setup functions for different data types
void setup_mixed_case(char** data, size_t size) {
    *data = malloc(size + 1);
    for (size_t i = 0; i < size; i++) {
        if (i % 2 == 0) {
            (*data)[i] = 'A' + (i % 26);
        } else {
            (*data)[i] = 'a' + (i % 26);
        }
    }
    (*data)[size] = '\0';
}

void setup_all_lower(char** data, size_t size) {
    *data = malloc(size + 1);
    for (size_t i = 0; i < size; i++) {
        (*data)[i] = 'a' + (i % 26);
    }
    (*data)[size] = '\0';
}

void setup_all_upper(char** data, size_t size) {
    *data = malloc(size + 1);
    for (size_t i = 0; i < size; i++) {
        (*data)[i] = 'A' + (i % 26);
    }
    (*data)[size] = '\0';
}

void setup_ascii_text(char** data, size_t size) {
    *data = malloc(size + 1);
    const char* sample = "The quick brown fox jumps over the lazy dog. ";
    size_t sample_len = strlen(sample);
    
    for (size_t i = 0; i < size; i++) {
        (*data)[i] = sample[i % sample_len];
    }
    (*data)[size] = '\0';
}

// Case conversion benchmarks
double benchmark_neon_to_upper(char* data, size_t size, int iterations) {
    char* work_buffer = malloc(size + 1);
    double start = get_time();
    
    for (int i = 0; i < iterations; i++) {
        memcpy(work_buffer, data, size + 1);
        neon_to_upper(work_buffer, size);
    }
    
    double end = get_time();
    free(work_buffer);
    return end - start;
}

double benchmark_std_to_upper(char* data, size_t size, int iterations) {
    char* work_buffer = malloc(size + 1);
    double start = get_time();
    
    for (int i = 0; i < iterations; i++) {
        memcpy(work_buffer, data, size + 1);
        std_to_upper(work_buffer, size);
    }
    
    double end = get_time();
    free(work_buffer);
    return end - start;
}

double benchmark_neon_to_lower(char* data, size_t size, int iterations) {
    char* work_buffer = malloc(size + 1);
    double start = get_time();
    
    for (int i = 0; i < iterations; i++) {
        memcpy(work_buffer, data, size + 1);
        neon_to_lower(work_buffer, size);
    }
    
    double end = get_time();
    free(work_buffer);
    return end - start;
}

double benchmark_std_to_lower(char* data, size_t size, int iterations) {
    char* work_buffer = malloc(size + 1);
    double start = get_time();
    
    for (int i = 0; i < iterations; i++) {
        memcpy(work_buffer, data, size + 1);
        std_to_lower(work_buffer, size);
    }
    
    double end = get_time();
    free(work_buffer);
    return end - start;
}

// UTF-8 validation benchmarks
double benchmark_neon_utf8_validate(char* data, size_t size, int iterations) {
    double start = get_time();
    
    for (int i = 0; i < iterations; i++) {
        neon_utf8_validate(data, size);
    }
    
    double end = get_time();
    return end - start;
}

double benchmark_std_utf8_validate(char* data, size_t size, int iterations) {
    double start = get_time();
    
    for (int i = 0; i < iterations; i++) {
        std_utf8_validate_simple(data, size);
    }
    
    double end = get_time();
    return end - start;
}


// Run a single benchmark
void run_benchmark(const char* name, 
                  double (*neon_func)(char*, size_t, int),
                  double (*std_func)(char*, size_t, int),
                  char* data, size_t size, int iterations) {
    
    printf("\n%s Benchmark (%zu bytes, %d iterations):\n", name, size, iterations);
    printf("----------------------------------------\n");
    
    double neon_time = neon_func(data, size, iterations);
    double std_time = std_func(data, size, iterations);
    
    double neon_throughput = (size * iterations) / (neon_time * 1024 * 1024 * 1024);
    double std_throughput = (size * iterations) / (std_time * 1024 * 1024 * 1024);
    double speedup = std_time / neon_time;
    
    printf("NEON implementation: %.4f seconds (%.2f GB/s)\n", neon_time, neon_throughput);
    printf("Standard library:    %.4f seconds (%.2f GB/s)\n", std_time, std_throughput);
    printf("Speedup: %.2fx\n", speedup);
    
    if (speedup > 1.0) {
        printf("✓ NEON is faster\n");
    } else if (speedup > 0.9) {
        printf("≈ Performance is similar\n");
    } else {
        printf("✗ Standard library is faster\n");
    }
}

int main() {
    printf("ARM String Operations Library Benchmark\n");
    printf("======================================\n");
    
    const size_t sizes[] = {1024, 16*1024, 256*1024, 1024*1024};
    const size_t num_sizes = sizeof(sizes) / sizeof(sizes[0]);
    const int iterations = 1000;
    
    for (size_t s = 0; s < num_sizes; s++) {
        size_t size = sizes[s];
        printf("\n" "=" "50" "s" "\n", "");
        printf("Testing with %zu bytes\n", size);
        printf("" "=" "50" "s" "\n", "");
        
        // Case conversion benchmarks
        char* mixed_data;
        setup_mixed_case(&mixed_data, size);
        run_benchmark("Case Conversion (to_upper)", 
                     benchmark_neon_to_upper, benchmark_std_to_upper,
                     mixed_data, size, iterations);
        
        run_benchmark("Case Conversion (to_lower)", 
                     benchmark_neon_to_lower, benchmark_std_to_lower,
                     mixed_data, size, iterations);
        free(mixed_data);
        
        // UTF-8 validation benchmarks
        char* ascii_data;
        setup_ascii_text(&ascii_data, size);
        run_benchmark("UTF-8 Validation", 
                     benchmark_neon_utf8_validate, benchmark_std_utf8_validate,
                     ascii_data, size, iterations);
        
        free(ascii_data);
    }
    
    printf("\n" "=" "50" "s" "\n", "");
    printf("Benchmark Complete\n");
    printf("Note: Results may vary based on CPU, memory, and system load.\n");
    printf("For best results, run on an ARMv8 system with NEON support.\n");
    
    return 0;
}