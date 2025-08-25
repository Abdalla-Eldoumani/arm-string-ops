# Testing Guide

## Quick Test

Create and run a basic functionality test:

```bash
cat > quick_test.c << 'EOF'
#include <stdio.h>
#include <string.h>
#include "arm_string_ops.h"

int main() {
    // Test case conversion
    char text[] = "Hello World!";
    printf("Original: %s\n", text);
    
    neon_to_upper(text, strlen(text));
    printf("Uppercase: %s\n", text);
    
    neon_to_lower(text, strlen(text));
    printf("Lowercase: %s\n", text);
    
    // Test UTF-8 validation
    const char* utf8_text = "Hello ASCII";
    int valid = neon_utf8_validate(utf8_text, strlen(utf8_text));
    size_t count = neon_utf8_count_chars(utf8_text, strlen(utf8_text));
    
    printf("UTF-8 valid: %s, chars: %zu\n", 
           valid ? "Yes" : "No", count);
    
    return 0;
}
EOF

# Compile and run
gcc -O3 -I include -o quick_test quick_test.c -L build -larm_string_ops
./quick_test
```

**Expected Output:**
```
Original: Hello World!
Uppercase: HELLO WORLD!
Lowercase: hello world!
UTF-8 valid: Yes, chars: 11
```

---

## Performance Test

Measure throughput with larger datasets:

```bash
cat > perf_test.c << 'EOF'
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <stdlib.h>
#include "arm_string_ops.h"

int main() {
    const size_t size = 1000000;  // 1MB
    char* buffer = malloc(size);
    
    // Fill with test data
    for (size_t i = 0; i < size-1; i++) {
        buffer[i] = 'a' + (i % 26);
    }
    buffer[size-1] = '\0';
    
    // Test case conversion performance
    clock_t start = clock();
    for (int i = 0; i < 100; i++) {
        neon_to_upper(buffer, size-1);
        neon_to_lower(buffer, size-1);
    }
    clock_t end = clock();
    
    double seconds = (double)(end - start) / CLOCKS_PER_SEC;
    double throughput = (size * 200) / (seconds * 1024 * 1024);
    
    printf("Case conversion: %.2f MB/s\n", throughput);
    
    // Test UTF-8 validation performance
    start = clock();
    for (int i = 0; i < 100; i++) {
        neon_utf8_validate(buffer, size-1);
    }
    end = clock();
    
    seconds = (double)(end - start) / CLOCKS_PER_SEC;
    throughput = (size * 100) / (seconds * 1024 * 1024);
    
    printf("UTF-8 validation: %.2f MB/s\n", throughput);
    
    free(buffer);
    return 0;
}
EOF

gcc -O3 -I include -o perf_test perf_test.c -L build -larm_string_ops
./perf_test
```

---

## Edge Case Tests

Test boundary conditions and edge cases:

```bash
cat > edge_test.c << 'EOF'
#include <stdio.h>
#include <string.h>
#include "arm_string_ops.h"

int main() {
    // Test empty string
    char empty[] = "";
    neon_to_upper(empty, 0);
    printf("Empty string: OK\n");
    
    // Test single character
    char single[] = "a";
    neon_to_upper(single, 1);
    printf("Single char 'a' -> '%s'\n", single);
    
    // Test very long string
    char long_str[1000];
    memset(long_str, 'x', 999);
    long_str[999] = '\0';
    neon_to_upper(long_str, 999);
    printf("Long string: %c%c%c...\n", 
           long_str[0], long_str[1], long_str[2]);
    
    // Test mixed content
    char mixed[] = "Hello123!@#";
    neon_to_upper(mixed, strlen(mixed));
    printf("Mixed content: %s\n", mixed);
    
    // Test UTF-8 edge cases
    printf("UTF-8 empty: %s\n", 
           neon_utf8_validate("", 0) ? "Valid" : "Invalid");
    printf("UTF-8 single: %s\n",
           neon_utf8_validate("A", 1) ? "Valid" : "Invalid");
    
    return 0;
}
EOF

gcc -O3 -I include -o edge_test edge_test.c -L build -larm_string_ops
./edge_test
```

---

## Cross-Platform Testing

### WSL/Linux ARM64 Emulation
```bash
# Install cross-compilation tools
sudo apt install gcc-aarch64-linux-gnu qemu-user-static

# Build for ARM64
aarch64-linux-gnu-gcc -static -I include -o test_arm64 quick_test.c -L build -larm_string_ops

# Run with QEMU
qemu-aarch64-static test_arm64
```

### Native ARM64 (Apple Silicon, Raspberry Pi)
```bash
# Build natively
gcc -O3 -march=armv8-a+simd -I include -o test_native quick_test.c -L build -larm_string_ops

# Run directly
./test_native
```

---

## Build Verification

Verify the library was built correctly:

```bash
# Check library contents
nm build/libarm_string_ops.a | grep neon_

# Should show:
# T neon_to_upper
# T neon_to_lower  
# T neon_utf8_validate
# T neon_utf8_count_chars

# Check architecture
file build/libarm_string_ops.a
# Should show: ARM aarch64 archive
```

---

## Troubleshooting

**Issue: Segmentation fault**
- Ensure you're passing valid pointers and lengths
- Check that strings are properly null-terminated for strlen()

**Issue: Poor performance**  
- Verify you're using `-O3` optimization flag
- Ensure strings are long enough to trigger SIMD (>16 bytes)

**Issue: Build errors**
- Check that you have ARM64 toolchain installed
- Verify include path points to correct header location