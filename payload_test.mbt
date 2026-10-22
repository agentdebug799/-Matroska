///|
/// Payload decoder vectors.

test "read_uint decodes big-endian values" {
  assert_eq(@matroska.read_uint(@matroska.Reader::new(b"\x01"), 1), 1)
  assert_eq(@matroska.read_uint(@matroska.Reader::new(b"\x0F\x42\x40"), 3), 1000000)
  assert_eq(@matroska.read_uint(@matroska.Reader::new(b"\x00\x00\x00\x2A"), 4), 42)
}

test "read_string decodes UTF-8" {
  let s = @matroska.read_string(@matroska.Reader::new(b"\x6D\x61\x74\x72\x6F\x73\x6B\x61"), 8)
  assert_eq(s, "matroska")
}

test "read_float decodes binary32 and binary64" {
  assert_eq(@matroska.read_float(@matroska.Reader::new(b"\x3F\x80\x00\x00"), 4), 1.0)
  assert_eq(@matroska.read_float(@matroska.Reader::new(b"\x3F\xF0\x00\x00\x00\x00\x00\x00"), 8), 1.0)
  assert_eq(@matroska.read_float(@matroska.Reader::new(b"\x40\x00\x00\x00\x00\x00\x00\x00"), 8), 2.0)
  assert_eq(@matroska.read_float(@matroska.Reader::new(b"\xC0\x00\x00\x00\x00\x00\x00\x00"), 8), -2.0)
  assert_eq(@matroska.read_float(@matroska.Reader::new(b"\x00\x00\x00\x00\x00\x00\x00\x00"), 8), 0.0)
}

test "read_float rejects a non-finite value" {
  let caught = try {
    let _ = @matroska.read_float(@matroska.Reader::new(b"\x7F\xF0\x00\x00\x00\x00\x00\x00"), 8)
    false
  } catch {
    _ => true
  }
  assert_true(caught)
}
