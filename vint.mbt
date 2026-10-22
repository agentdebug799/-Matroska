///|
/// EBML variable-length integers (RFC 8794 §4), used for both element IDs and
/// element data sizes.

/// A decoded VINT together with the number of bytes its encoding occupied.
pub struct Vint {
  /// Number of bytes in the encoded VINT (1 to 8).
  length : Int
  /// The decoded numeric value (the marker bits are not part of the value).
  value : UInt64
}

/// Count the number of leading zero bits in an 8-bit value (0..=8).
fn leading_zeros8(b : Int) -> Int {
  let mut n = 0
  let mut mask = 0x80
  while mask > 0 && (b & mask) == 0 {
    n = n + 1
    mask = mask >> 1
  }
  n
}

/// Decode a VINT of at most `max_len` bytes from `r`.
///
/// The first byte's leading-zero count determines the encoded length. A VINT
/// longer than `max_len` is rejected so that element IDs (4 bytes) and data
/// sizes (8 bytes) stay within their bounds.
pub fn read_vint(r : Reader, max_len : Int) -> Vint raise MatroskaError {
  let b0 = r.read_u8()
  if b0 == 0 {
    raise InvalidVint
  }
  let length = leading_zeros8(b0) + 1
  if length > max_len {
    raise InvalidVint
  }
  let value_bits = 8 - length
  let mut value : UInt64 = (b0 & ((1 << value_bits) - 1)).to_uint64()
  let mut i = 1
  while i < length {
    value = (value << 8) | r.read_u8().to_uint64()
    i = i + 1
  }
  { length: length, value: value }
}

/// Reconstruct the full raw byte value of the VINT (marker bits included).
///
/// This is how Matroska element IDs are conventionally written: the EBML
/// header element is the raw bytes `0x1A45DFA3`, while its VINT value is
/// `0x0A45DFA3`.
pub fn Vint::raw(self : Vint) -> UInt64 {
  let marker : UInt64 = (1 << (8 - self.length)).to_uint64()
  (marker << (8 * (self.length - 1))) | self.value
}

/// The all-ones value for a VINT of the given length (`2^(7*length) - 1`).
fn unknown_value(length : Int) -> UInt64 {
  let bits = 7 * length
  (1UL << bits) - 1UL
}

/// True when the VINT encodes the reserved "unknown size" marker (all data
/// bits set to 1).
pub fn is_unknown(v : Vint) -> Bool {
  v.value == unknown_value(v.length)
}
