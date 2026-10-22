///|
/// Block parsing and lacing vectors.

test "SimpleBlock without lacing" {
  let b = @matroska.read_block(@matroska.Reader::new(b"\x81\x00\x00\x80\x41\x42\x43"), 7)
  assert_eq(b.track_number, 1)
  assert_eq(b.timecode, 0)
  assert_true(b.keyframe)
  assert_false(b.invisible)
  assert_eq(b.lacing, 0)
  assert_eq(b.frames.length(), 1)
  assert_eq(b.frames[0], b"\x41\x42\x43")
}

test "fixed lacing splits two frames evenly" {
  let b = @matroska.read_block(@matroska.Reader::new(b"\x81\x00\x05\x04\x01\x41\x42\x43\x44"), 9)
  assert_eq(b.track_number, 1)
  assert_eq(b.timecode, 5)
  assert_eq(b.lacing, 2)
  assert_eq(b.frames.length(), 2)
  assert_eq(b.frames[0], b"\x41\x42")
  assert_eq(b.frames[1], b"\x43\x44")
}

test "Xiph lacing splits variable-size frames" {
  let b = @matroska.read_block(@matroska.Reader::new(b"\x81\x00\x00\x02\x01\x01\x41\x42\x43"), 9)
  assert_eq(b.lacing, 1)
  assert_eq(b.frames.length(), 2)
  assert_eq(b.frames[0], b"\x41")
  assert_eq(b.frames[1], b"\x42\x43")
}

test "EBML lacing handles signed deltas" {
  let b = @matroska.read_block(@matroska.Reader::new(b"\x81\x00\x00\x06\x01\x82\xFF\x41\x42\x43"), 9)
  assert_eq(b.lacing, 3)
  assert_eq(b.frames.length(), 2)
  assert_eq(b.frames[0], b"\x41\x42")
  assert_eq(b.frames[1], b"\x43")
}

test "a negative timecode sign-extends" {
  let b = @matroska.read_block(@matroska.Reader::new(b"\x81\xFF\xFF\x80\x41"), 5)
  assert_eq(b.timecode, -1)
  assert_eq(b.frames[0], b"\x41")
}
