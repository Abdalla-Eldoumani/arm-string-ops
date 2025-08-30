# ARMv8 NEON String Operations Library Makefile

# Compiler and tools
CC = gcc
AS = as
AR = ar
STRIP = strip

# Target architecture and optimization
ARCH_FLAGS = -march=armv8-a+simd
OPT_FLAGS = -O3 -ffast-math
SIMD_FLAGS = -mstrict-align

# Directories
SRC_DIR = src
INCLUDE_DIR = include
TEST_DIR = test
DOCS_DIR = docs
BUILD_DIR = build
OBJ_DIR = $(BUILD_DIR)/obj

# Library name
LIB_NAME = arm_string_ops
STATIC_LIB = lib$(LIB_NAME).a
SHARED_LIB = lib$(LIB_NAME).so

# Assembly source files (only working functions)
ASM_SOURCES = $(SRC_DIR)/case_ops.S $(SRC_DIR)/utf8_ops.S
ASM_OBJECTS = $(ASM_SOURCES:$(SRC_DIR)/%.S=$(OBJ_DIR)/%.o)

# Test sources
TEST_SOURCES = $(wildcard $(TEST_DIR)/*.c)
TEST_BINARIES = $(TEST_SOURCES:$(TEST_DIR)/%.c=$(BUILD_DIR)/%)

# Compiler flags
CFLAGS = $(ARCH_FLAGS) $(OPT_FLAGS) -Wall -Wextra -I$(INCLUDE_DIR)
CFLAGS += -fPIC -std=c99
ASFLAGS = $(ARCH_FLAGS) -I$(INCLUDE_DIR)

# Shared library flags
SHARED_FLAGS = -shared -fPIC -Wl,-soname,$(SHARED_LIB)

# Default target
.PHONY: all
all: $(BUILD_DIR)/$(STATIC_LIB) $(BUILD_DIR)/$(SHARED_LIB)

# Create build directories
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(OBJ_DIR):
	mkdir -p $(OBJ_DIR)

# Compile assembly sources
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.S | $(OBJ_DIR)
	$(AS) $(ASFLAGS) -o $@ $<

# Create static library
$(BUILD_DIR)/$(STATIC_LIB): $(ASM_OBJECTS) | $(BUILD_DIR)
	$(AR) rcs $@ $(ASM_OBJECTS)
	@echo "Static library created: $@"

# Create shared library
$(BUILD_DIR)/$(SHARED_LIB): $(ASM_OBJECTS) | $(BUILD_DIR)
	$(CC) $(SHARED_FLAGS) -o $@ $(ASM_OBJECTS)
	@echo "Shared library created: $@"

# Build test programs from test directory
.PHONY: tests
tests: $(BUILD_DIR)/test_harness $(BUILD_DIR)/benchmark

# Build test harness from existing source
$(BUILD_DIR)/test_harness: $(TEST_DIR)/test_harness.c $(BUILD_DIR)/$(STATIC_LIB) | $(BUILD_DIR)
	@echo "Building test harness..."
	$(CC) $(CFLAGS) -o $@ $< $(BUILD_DIR)/$(STATIC_LIB)
	@echo "Test harness built: $@"

# Build benchmark from existing source
$(BUILD_DIR)/benchmark: $(TEST_DIR)/benchmark.c $(BUILD_DIR)/$(STATIC_LIB) | $(BUILD_DIR)
	@echo "Building benchmark..."
	$(CC) $(CFLAGS) -o $@ $< $(BUILD_DIR)/$(STATIC_LIB)
	@echo "Benchmark built: $@"

# Run tests
.PHONY: test
test: tests
	@echo "Running test harness..."
	$(BUILD_DIR)/test_harness

# Run benchmark
.PHONY: benchmark
benchmark: $(BUILD_DIR)/benchmark
	@echo "Running benchmark..."
	$(BUILD_DIR)/benchmark

# Install libraries (requires sudo)
.PHONY: install
install: $(BUILD_DIR)/$(STATIC_LIB) $(BUILD_DIR)/$(SHARED_LIB)
	@echo "Installing libraries..."
	sudo cp $(BUILD_DIR)/$(STATIC_LIB) /usr/local/lib/
	sudo cp $(BUILD_DIR)/$(SHARED_LIB) /usr/local/lib/
	sudo cp $(INCLUDE_DIR)/arm_string_ops.h /usr/local/include/
	sudo ldconfig
	@echo "Installation complete"

# Uninstall
.PHONY: uninstall
uninstall:
	@echo "Uninstalling libraries..."
	sudo rm -f /usr/local/lib/$(STATIC_LIB)
	sudo rm -f /usr/local/lib/$(SHARED_LIB)
	sudo rm -f /usr/local/include/arm_string_ops.h
	sudo ldconfig
	@echo "Uninstallation complete"

# Debug build (with debug symbols)
.PHONY: debug
debug: CFLAGS += -g -DDEBUG -O0
debug: ASFLAGS += -g
debug: all

# Release build (stripped)
.PHONY: release
release: all
	$(STRIP) $(BUILD_DIR)/$(STATIC_LIB)
	$(STRIP) $(BUILD_DIR)/$(SHARED_LIB)
	@echo "Release build complete"

# Clean build artifacts
.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
	@echo "Build artifacts cleaned"

# Show build information
.PHONY: info
info:
	@echo "ARMv8 NEON String Operations Library"
	@echo "====================================="
	@echo "Architecture: $(ARCH_FLAGS)"
	@echo "Optimization: $(OPT_FLAGS)"
	@echo "Compiler: $(CC)"
	@echo "Assembler: $(AS)"
	@echo ""
	@echo "Working Functions:"
	@echo "  • Case conversion (neon_to_upper/lower)"
	@echo "  • UTF-8 operations (validate/count_chars)"
	@echo ""
	@echo "Available targets:"
	@echo "  all      - Build static and shared libraries"
	@echo "  tests    - Build and run test suite"
	@echo "  test     - Run functionality tests"
	@echo "  debug    - Build with debug symbols"
	@echo "  release  - Build optimized and stripped"
	@echo "  install  - Install libraries system-wide"
	@echo "  clean    - Remove build artifacts"
	@echo "  info     - Show this information"

# Check for ARMv8 support
.PHONY: check-arch
check-arch:
	@echo "Checking for ARMv8 SIMD support..."
	@if [ -f /proc/cpuinfo ]; then \
		if grep -q "asimd" /proc/cpuinfo; then \
			echo "✓ ARMv8 SIMD (NEON) support detected"; \
		else \
			echo "✗ ARMv8 SIMD support not found"; \
			echo "Warning: This library requires ARMv8 with NEON support"; \
		fi \
	else \
		echo "Cannot determine CPU features (not on Linux)"; \
	fi

# Dependency tracking
-include $(ASM_OBJECTS:.o=.d)