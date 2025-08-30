# ARMv8 NEON String Operations

High-performance string processing library using ARMv8 NEON SIMD instructions.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-ARM64-blue.svg)](https://developer.arm.com/architectures/cpu-architecture/a-profile)

## Features

**⚡ SIMD-Accelerated Operations**
- **Case Conversion**: In-place ASCII case conversion (~1 GB/s throughput)
- **UTF-8 Processing**: Fast validation and character counting (~800 MB/s throughput)

**🔧 Production Ready** 
- Zero external dependencies
- Memory-safe with bounds checking
- Cross-platform ARM64 support

## Quick Start

```c
#include "arm_string_ops.h"

char text[] = "Hello World";
neon_to_upper(text, strlen(text));         // "HELLO WORLD"

size_t chars = neon_utf8_count_chars(text, strlen(text));  // 11
int valid = neon_utf8_validate(text, strlen(text));        // 1 (true)
```

## API Reference

| Function | Description | Performance |
|----------|-------------|-------------|
| `neon_to_upper(str, len)` | Convert ASCII to uppercase in-place | ~1 GB/s |
| `neon_to_lower(str, len)` | Convert ASCII to lowercase in-place | ~1 GB/s |
| `neon_utf8_validate(str, len)` | Validate UTF-8 encoding | ~800 MB/s |
| `neon_utf8_count_chars(str, len)` | Count Unicode characters | ~800 MB/s |

See [`docs/API.md`](docs/API.md) for detailed documentation.

## Building

### Native ARM64 (Raspberry Pi, Apple Silicon, etc.)
```bash
# On native ARM64 hardware
make clean
make all      # Build library
make test     # Run tests
make benchmark # Run performance tests
```

### Cross-Compilation in WSL (x86_64 → ARM64)
```bash
# Install tools in WSL/Ubuntu
sudo apt update
sudo apt install gcc-aarch64-linux-gnu qemu-user libc6-arm64-cross

# Build and test with QEMU
make -f Makefile.wsl clean
make -f Makefile.wsl tests
make -f Makefile.wsl test      # Runs with QEMU emulation
```

### Platform-Specific Instructions

#### Apple Silicon Mac (M1/M2/M3)
```bash
# Modify Makefile to use clang
sed -i '' 's/gcc/clang/g' Makefile
sed -i '' 's/as/as -arch arm64/g' Makefile

# Build and test
make clean && make test
```

#### Raspberry Pi 4/5 (64-bit OS)
```bash
# Install build tools if needed
sudo apt-get install build-essential

# Build and benchmark
make clean && make benchmark
```

#### Android (Termux)
```bash
# In Termux
pkg install clang make
export CC=clang
make clean && make all
```

See [`docs/BUILDING.md`](docs/BUILDING.md) for detailed build instructions.

## Performance

Benchmarked on ARM Cortex-A72 (1.8GHz):

| Operation | NEON Library | Standard Library | Speedup |
|-----------|--------------|------------------|---------|
| Case conversion | 1.2 GB/s | 150 MB/s | 8x |
| UTF-8 validation | 850 MB/s | 280 MB/s | 3x |

*Results vary by CPU architecture and data characteristics.*

## Technical Details

**SIMD Strategy:**
- Process 16 bytes per NEON instruction
- Automatic scalar fallback for short strings
- Unaligned memory handling

**Compliance:**
- AAPCS64 calling convention
- ARMv8 instruction set
- POSIX-compatible

## Requirements

- ARMv8 CPU with NEON support
- GNU assembler 
- GCC or Clang

**Supported Platforms:**
- Linux ARM64
- macOS Apple Silicon  
- Raspberry Pi 4+
- AWS Graviton
- Android (ARMv8)

## Testing

Quick functionality test:
```bash
# Native ARM
make tests && build/test_harness

# WSL with QEMU
make -f Makefile.wsl test
```

See [`docs/TESTING.md`](docs/TESTING.md) for comprehensive testing guide.

## Integration Example

```c
// myapp.c
#include "arm_string_ops.h"
#include <stdio.h>
#include <string.h>

int main() {
    char buffer[] = "hello world";
    
    neon_to_upper(buffer, strlen(buffer));
    printf("%s\n", buffer);  // HELLO WORLD
    
    if (neon_utf8_validate(buffer, strlen(buffer))) {
        printf("Valid UTF-8 with %zu characters\n", 
               neon_utf8_count_chars(buffer, strlen(buffer)));
    }
    
    return 0;
}
```

Compile:
```bash
gcc -O3 -o myapp myapp.c -L./build -larm_string_ops
```

## Project Structure

```
├── include/arm_string_ops.h    # Public API
├── src/                        # ARMv8 assembly source
│   ├── case_ops.S             # Case conversion operations
│   └── utf8_ops.S             # UTF-8 operations
├── docs/                       # Documentation
│   ├── API.md                 # API reference
│   ├── BUILDING.md            # Build instructions
│   └── TESTING.md             # Testing guide
├── test/                       # Test suite
│   ├── test_harness.c         # Functionality tests
│   └── benchmark.c            # Performance benchmarks
├── bindings/                   # Language bindings
│   └── rust/lib.rs            # Rust FFI bindings
├── Makefile                    # Native build
├── Makefile.wsl               # WSL cross-compilation
└── WSL_SETUP_GUIDE.md         # WSL setup instructions
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.