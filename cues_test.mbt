///|
/// Cues parsing vectors.

test "read_cues decodes a cue point" {
  // Cues with one CuePoint: time 5, track 1, cluster position 42, block 3.
  let r = @matroska.Reader::new(b"\x1C\x53\xBB\x6B\x91\xBB\x8F\xB3\x81\x05\xB7\x8A\xF7\x81\x01\xF1\x81\x2A\x53\x78\x81\x03")
  let e = @matroska.read_element(r)
  assert_eq(e.id, @matroska.Cues)
  let c = @matroska.read_cues(r, e.size.to_int())
  assert_eq(c.points.length(), 1)
  assert_eq(c.points[0].time, 5)
  assert_eq(c.points[0].track_positions.length(), 1)
  assert_eq(c.points[0].track_positions[0].track, 1)
  assert_eq(c.points[0].track_positions[0].cluster_position, 42)
  assert_eq(c.points[0].track_positions[0].block_number, 3)
}
