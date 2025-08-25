# API Reference

## Case Conversion Functions

### `neon_to_upper(char* str, size_t len)`
Converts ASCII characters to uppercase in-place.

**Parameters:**
- `str`: Pointer to null-terminated string (will be modified)  
- `len`: Length of string in bytes

**Behavior:**
- Only ASCII characters (a-z) are converted to uppercase
- Non-ASCII bytes remain unchanged
- Uses SIMD acceleration for strings >16 bytes
- Handles unaligned memory access automatically

**Example:**
```c
char text[] = "hello world";
neon_to_upper(text, strlen(text));
// text is now "HELLO WORLD"
```

---

### `neon_to_lower(char* str, size_t len)` 
Converts ASCII characters to lowercase in-place.

**Parameters:**
- `str`: Pointer to null-terminated string (will be modified)
- `len`: Length of string in bytes  

**Behavior:**
- Only ASCII characters (A-Z) are converted to lowercase
- Non-ASCII bytes remain unchanged
- Uses SIMD acceleration for strings >16 bytes
- Handles unaligned memory access automatically

**Example:**
```c
char text[] = "HELLO WORLD";
neon_to_lower(text, strlen(text));
// text is now "hello world"
```

---

## UTF-8 Functions

### `neon_utf8_validate(const char* str, size_t len)`
Validates UTF-8 encoding using SIMD acceleration.

**Parameters:**
- `str`: Pointer to string to validate
- `len`: Length of string in bytes

**Returns:**
- `1` if string contains valid UTF-8
- `0` if invalid UTF-8 sequences found

**Behavior:**
- Fast ASCII path for strings with only ASCII characters
- Detects invalid start bytes, continuation bytes, and incomplete sequences
- Uses SIMD for initial ASCII detection

**Example:**
```c
const char* text = "Hello 世界";
if (neon_utf8_validate(text, strlen(text))) {
    printf("Valid UTF-8\n");
}
```

---

### `neon_utf8_count_chars(const char* str, size_t len)`
Counts Unicode characters (not bytes) in UTF-8 string.

**Parameters:**  
- `str`: Pointer to UTF-8 string
- `len`: Length of string in bytes

**Returns:**
- Number of Unicode characters (not bytes)

**Behavior:**
- Fast ASCII path counts 1 character per byte
- For mixed content, counts UTF-8 character start bytes
- Uses SIMD to process 16 bytes at a time

**Example:**
```c
const char* text = "café";  // 4 characters, 5 bytes
size_t chars = neon_utf8_count_chars(text, strlen(text));
// chars = 4 (not 5)
```

---

## Performance Notes

- **Alignment**: Functions automatically handle unaligned inputs
- **SIMD Usage**: Triggered for strings longer than 16 bytes  
- **Throughput**: ~1GB/s for case conversion, ~800MB/s for UTF-8 operations
- **Memory**: In-place operations minimize memory allocation