//! Rust FFI bindings for the ARMv8 NEON String Operations Library
//! 
//! This crate provides safe Rust bindings to a high-performance string operations
//! library written in ARMv8 assembly with NEON SIMD acceleration.
//! 
//! # Features
//! 
//! - **Case Conversion**: Fast ASCII case conversion using SIMD
//! - **UTF-8 Operations**: Validation and character counting
//! 
//! # Example
//! 
//! ```rust
//! use arm_string_ops::*;
//! 
//! let mut text = "Hello World".to_string();
//! to_upper_inplace(&mut text);
//! assert_eq!(text, "HELLO WORLD");
//! ```

use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int};
use std::ptr;

/// Error types for string operations
#[derive(Debug, Clone, PartialEq)]
pub enum StringOpsError {
    /// Invalid UTF-8 sequence
    InvalidUtf8,
}

impl std::fmt::Display for StringOpsError {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        match self {
            StringOpsError::InvalidUtf8 => write!(f, "Invalid UTF-8 sequence"),
        }
    }
}

impl std::error::Error for StringOpsError {}

// Raw FFI declarations
extern "C" {
    fn neon_to_upper(str: *mut c_char, len: usize);
    fn neon_to_lower(str: *mut c_char, len: usize);
    fn neon_utf8_validate(str: *const c_char, len: usize) -> c_int;
    fn neon_utf8_count_chars(str: *const c_char, len: usize) -> usize;
}

/// Convert ASCII characters to uppercase in-place
/// 
/// Only ASCII characters (0-127) are converted. Non-ASCII bytes remain unchanged.
/// 
/// # Example
/// 
/// ```rust
/// let mut text = "Hello World!".to_string();
/// to_upper_inplace(&mut text);
/// assert_eq!(text, "HELLO WORLD!");
/// ```
pub fn to_upper_inplace(text: &mut String) {
    unsafe {
        let bytes = text.as_mut_vec();
        neon_to_upper(bytes.as_mut_ptr() as *mut c_char, bytes.len());
    }
}

/// Convert ASCII characters to lowercase in-place
/// 
/// Only ASCII characters (0-127) are converted. Non-ASCII bytes remain unchanged.
/// 
/// # Example
/// 
/// ```rust
/// let mut text = "HELLO WORLD!".to_string();
/// to_lower_inplace(&mut text);
/// assert_eq!(text, "hello world!");
/// ```
pub fn to_lower_inplace(text: &mut String) {
    unsafe {
        let bytes = text.as_mut_vec();
        neon_to_lower(bytes.as_mut_ptr() as *mut c_char, bytes.len());
    }
}


/// Validate UTF-8 encoding
/// 
/// Returns `Ok(())` if the string contains valid UTF-8, otherwise returns an error.
/// 
/// # Example
/// 
/// ```rust
/// assert!(utf8_validate("Hello 世界").is_ok());
/// assert!(utf8_validate("Hello World").is_ok());
/// ```
pub fn utf8_validate(text: &str) -> Result<(), StringOpsError> {
    unsafe {
        let result = neon_utf8_validate(
            text.as_ptr() as *const c_char,
            text.len()
        );
        
        if result == 1 {
            Ok(())
        } else {
            Err(StringOpsError::InvalidUtf8)
        }
    }
}

/// Count UTF-8 characters (not bytes)
/// 
/// Returns the number of Unicode characters in the string.
/// 
/// # Example
/// 
/// ```rust
/// assert_eq!(utf8_char_count("Hello"), 5);
/// assert_eq!(utf8_char_count("café"), 4); // é counts as 1 character
/// assert_eq!(utf8_char_count("世界"), 2);
/// ```
pub fn utf8_char_count(text: &str) -> usize {
    unsafe {
        neon_utf8_count_chars(
            text.as_ptr() as *const c_char,
            text.len()
        )
    }
}


/// Trait for string slice extensions
pub trait StringOpsExt {
    /// Validate UTF-8 encoding
    fn validate_utf8(&self) -> Result<(), StringOpsError>;
    
    /// Count UTF-8 characters
    fn char_count_utf8(&self) -> usize;
}

impl StringOpsExt for str {
    fn validate_utf8(&self) -> Result<(), StringOpsError> {
        utf8_validate(self)
    }
    
    fn char_count_utf8(&self) -> usize {
        utf8_char_count(self)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_case_conversion() {
        let mut text = "Hello World!".to_string();
        to_upper_inplace(&mut text);
        assert_eq!(text, "HELLO WORLD!");
        
        to_lower_inplace(&mut text);
        assert_eq!(text, "hello world!");
    }

    #[test]
    fn test_utf8_operations() {
        assert!(utf8_validate("Hello World").is_ok());
        assert!(utf8_validate("Hello ASCII").is_ok());
        
        assert_eq!(utf8_char_count("Hello"), 5);
        assert_eq!(utf8_char_count("Hello World"), 11);
    }

    #[test]
    fn test_string_ext_trait() {
        use StringOpsExt;
        
        let text = "Hello World";
        assert!(text.validate_utf8().is_ok());
        assert_eq!(text.char_count_utf8(), 11);
    }
}