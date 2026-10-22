///|
/// Big-endian byte cursor behaviour.

test "read_u8 advances the cursor" {
  let r = @matroska.Reader::new(b"\x01\x02\x03")
  assert_eq(r.read_u8(), 1)
  assert_eq(r.pos(), 1)
  assert_eq(r.read_u8(), 2)
  assert_eq(r.remaining(), 1)
  assert_false(r.eof())
  assert_eq(r.read_u8(), 3)
  assert_true(r.eof())
}

test "big-endian multi-byte reads" {
  assert_eq(@matroska.Reader::new(b"\x12\x34").read_u16(), 0x1234)
  assert_eq(@matroska.Reader::new(b"\x12\x34\x56\x78").read_u32(), 0x12345678)
  assert_eq(@matroska.Reader::new(b"\x00\x00\x00\x00\x00\x00\x00\x2A").read_u64().to_int(), 42)
}

test "read_bytes returns exactly n bytes" {
  let r = @matroska.Reader::new(b"\x01\x02\x03\x04")
  let b = r.read_bytes(2)
  assert_eq(b.length(), 2)
  assert_eq(b[0].to_int(), 1)
  assert_eq(b[1].to_int(), 2)
  assert_eq(r.pos(), 2)
  assert_eq(r.remaining(), 2)
}

test "skip advances past bytes" {
  let r = @matroska.Reader::new(b"\x01\x02\x03")
  r.skip(2)
  assert_eq(r.pos(), 2)
  assert_eq(r.peek_u8(), 3)
}

test "reads past the end raise Truncated" {
  let caught = try {
    let _ = @matroska.Reader::new(b"\x01").read_u16()
    false
  } catch {
    _ => true
  }
  assert_true(caught)
}
