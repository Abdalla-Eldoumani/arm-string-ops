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

### Native ARM64
```bash
make all      # Build library
make test     # Run tests
```

### Cross-Compilation (x86_64 → ARM64)
```bash
# Ubuntu/WSL
sudo apt install gcc-aarch64-linux-gnu qemu-user-static

# Build and test
make -f Makefile.cross all
qemu-aarch64-static build/test_harness
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

## Testing

Quick functionality test:
```bash
# See docs/TESTING.md for comprehensive testing guide
make tests && build/test_harness
```

## Project Structure

```
├── include/arm_string_ops.h    # Public API
├── src/                        # ARMv8 assembly source
├── docs/                       # Documentation
├── test/                       # Test suite
└── Makefile                    # Build system
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
