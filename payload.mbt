///|
/// Decoders for EBML element payloads: unsigned integers, UTF-8 strings and
/// IEEE 754 floats.

/// Decode an unsigned big-endian integer from the next `n` bytes (1..=8).
///
/// Callers should keep `n` small enough that the result fits an `Int`; the
/// Matroska unsigned fields this library reads (track numbers, flags, sample
/// rates, timecode scale) are all well within 31 bits.
pub fn read_uint(r : Reader, n : Int) -> Int raise MatroskaError {
  let mut v = 0
  let mut i = 0
  while i < n {
    v = (v << 8) | r.read_u8()
    i = i + 1
  }
  v
}

/// Decode a UTF-8 string from the next `n` bytes.
pub fn read_string(r : Reader, n : Int) -> String raise MatroskaError {
  @utf8.decode_lossy(r.read_bytes(n))
}

/// Decode an IEEE 754 big-endian float from the next `n` bytes (4 or 8).
pub fn read_float(r : Reader, n : Int) -> Double raise MatroskaError {
  if n == 4 {
    Float::reinterpret_from_uint(r.read_u32().reinterpret_as_uint()).to_double()
  } else if n == 8 {
    double_from_bits(r.read_u64())
  } else {
    raise InvalidEbml
  }
}

/// Reconstruct an IEEE 754 binary64 from its raw bit pattern.
fn double_from_bits(bits : UInt64) -> Double raise MatroskaError {
  let sign = if (bits >> 63).to_int() == 0 { 1.0 } else { -1.0 }
  let exp = ((bits >> 52) & 0x7FFUL).to_int()
  let frac = bits & 0xFFFFFFFFFFFFFUL
  if exp == 0 {
    // Zero or subnormal: frac * 2^-1074.
    sign * @math.scalbn(frac.to_double(), -1074)
  } else if exp == 0x7FF {
    raise Unsupported("non-finite float")
  } else {
    // Normal: (2^52 + frac) * 2^(exp - 1075).
    let sig = (frac + (1UL << 52)).to_double()
    sign * @math.scalbn(sig, exp - 1075)
  }
}
