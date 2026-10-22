///|
/// VINT decoding and "unknown size" vectors (RFC 8794 §4).

test "one-byte VINT" {
  let v = @matroska.read_vint(@matroska.Reader::new(b"\x81"), 8)
  assert_eq(v.length, 1)
  assert_eq(v.value.to_int(), 1)
  assert_false(@matroska.is_unknown(v))
}

test "one-byte max value is the unknown-size marker" {
  let v = @matroska.read_vint(@matroska.Reader::new(b"\xFF"), 8)
  assert_eq(v.length, 1)
  assert_eq(v.value.to_int(), 127)
  assert_true(@matroska.is_unknown(v))
}

test "two-byte VINT" {
  let v = @matroska.read_vint(@matroska.Reader::new(b"\x40\x01"), 8)
  assert_eq(v.length, 2)
  assert_eq(v.value.to_int(), 1)
  assert_false(@matroska.is_unknown(v))
}

test "two-byte unknown-size marker" {
  let v = @matroska.read_vint(@matroska.Reader::new(b"\x7F\xFF"), 8)
  assert_eq(v.length, 2)
  assert_eq(v.value.to_int(), 16383)
  assert_true(@matroska.is_unknown(v))
}

test "four-byte VINT raw reconstruction" {
  // The EBML header ID: raw bytes 1A 45 DF A3, VINT value 0A 45 DF A3.
  let v = @matroska.read_vint(@matroska.Reader::new(b"\x1A\x45\xDF\xA3"), 4)
  assert_eq(v.length, 4)
  assert_eq(v.value.to_int(), 0x0A45DFA3)
  assert_eq(v.raw().to_int(), 0x1A45DFA3)
}

test "eight-byte VINT" {
  let v = @matroska.read_vint(@matroska.Reader::new(b"\x01\x00\x00\x00\x00\x00\x00\x01"), 8)
  assert_eq(v.length, 8)
  assert_eq(v.value.to_int(), 1)
}

test "a leading zero first byte is invalid" {
  let caught = try {
    let _ = @matroska.read_vint(@matroska.Reader::new(b"\x00\x80"), 8)
    false
  } catch {
    _ => true
  }
  assert_true(caught)
}

test "a VINT longer than the bound is rejected" {
  let caught = try {
    let _ = @matroska.read_vint(@matroska.Reader::new(b"\x1A\x45\xDF\xA3"), 2)
    false
  } catch {
    _ => true
  }
  assert_true(caught)
}
