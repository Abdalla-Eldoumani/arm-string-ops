# Building Guide

## Native ARM64 Build

For native ARM64 systems (Apple Silicon, ARM64 Linux):

```bash
# Build the library
make all

# Build and run tests
make tests
make test
```

---

## Cross-Compilation (x86_64 → ARM64)

### Ubuntu/WSL Setup

```bash
# Install cross-compilation tools
sudo apt update
sudo apt install gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu qemu-user-static

# Create cross-compilation Makefile
cp Makefile Makefile.cross
sed -i 's/CC = gcc/CC = aarch64-linux-gnu-gcc/' Makefile.cross
sed -i 's/AS = as/AS = aarch64-linux-gnu-as/' Makefile.cross
sed -i 's/AR = ar/AR = aarch64-linux-gnu-ar/' Makefile.cross
sed -i 's/-std=c99/-std=c99 -static/' Makefile.cross

# Build
make -f Makefile.cross all

# Test with QEMU
make -f Makefile.cross tests
qemu-aarch64-static build/test_harness
```

### macOS Cross-Compilation

```bash
# Install ARM64 toolchain (if cross-compiling)
brew install gcc-aarch64-linux-gnu

# Use cross-compilation Makefile as above
make -f Makefile.cross all
```

---

## Build Targets

- `make all` - Build static and shared libraries
- `make tests` - Build test programs  
- `make clean` - Remove build artifacts
- `make info` - Show build configuration

---

## Build Requirements

### System Requirements
- ARMv8 architecture with NEON support
- GNU assembler with ARMv8 support
- GCC or Clang with ARM64 target

### Dependencies
- No external runtime dependencies
- Standard C library only
- POSIX-compatible system

---

## Optimization Flags

The library uses these optimization settings:

```makefile
ARCH_FLAGS = -march=armv8-a+simd
OPT_FLAGS = -O3 -ffast-math
CFLAGS = -Wall -Wextra -fPIC -std=c99
```

**Key flags:**
- `-march=armv8-a+simd`: Enable ARMv8 and NEON instructions
- `-O3`: Maximum optimization for performance
- `-ffast-math`: Aggressive floating-point optimizations
- `-fPIC`: Position-independent code for shared libraries

---

## Build Verification

Check that libraries were built correctly:

```bash
# Verify file types
file build/libarm_string_ops.a
file build/libarm_string_ops.so

# Check exported symbols  
nm build/libarm_string_ops.a | grep neon_

# Expected output:
# 00000000 T neon_to_upper
# 00000000 T neon_to_lower
# 00000000 T neon_utf8_validate
# 00000000 T neon_utf8_count_chars
```

---

## Integration

### Static Linking
```bash
gcc -I include -o myapp myapp.c -L build -larm_string_ops
```

### Dynamic Linking
```bash  
gcc -I include -o myapp myapp.c -L build -larm_string_ops
export LD_LIBRARY_PATH=./build:$LD_LIBRARY_PATH
./myapp
```

### CMake Integration
```cmake
find_library(ARM_STRING_OPS 
    NAMES arm_string_ops
    PATHS ${CMAKE_SOURCE_DIR}/build
)

target_link_libraries(myapp ${ARM_STRING_OPS})
target_include_directories(myapp PRIVATE ${CMAKE_SOURCE_DIR}/include)
```