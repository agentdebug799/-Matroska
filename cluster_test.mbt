///|
/// Cluster parsing and frame extraction vectors.

test "read_cluster extracts timecode and SimpleBlock frames" {
  // Cluster (timecode 0) with one SimpleBlock (track 1, keyframe, "ABC").
  let r = @matroska.Reader::new(b"\x1F\x43\xB6\x75\x8C\xE7\x81\x00\xA3\x87\x81\x00\x00\x80\x41\x42\x43")
  let e = @matroska.read_element(r)
  assert_eq(e.id, @matroska.Cluster)
  let c = @matroska.read_cluster(r, e.size.to_int())
  assert_eq(c.timecode, 0)
  assert_eq(c.frames.length(), 1)
  assert_eq(c.frames[0].track_number, 1)
  assert_eq(c.frames[0].timecode, 0)
  assert_true(c.frames[0].keyframe)
  assert_eq(c.frames[0].duration, 0)
  assert_eq(c.frames[0].data, b"\x41\x42\x43")
}

test "read_cluster extracts frames from a BlockGroup" {
  // Cluster (timecode 100) with one BlockGroup containing a Block + BlockDuration.
  let r = @matroska.Reader::new(b"\x1F\x43\xB6\x75\x8F\xE7\x81\x64\xA0\x8A\xA1\x85\x81\x00\x00\x00\x44\x9B\x81\x0A")
  let e = @matroska.read_element(r)
  let c = @matroska.read_cluster(r, e.size.to_int())
  assert_eq(c.timecode, 100)
  assert_eq(c.frames.length(), 1)
  assert_eq(c.frames[0].track_number, 1)
  assert_eq(c.frames[0].timecode, 100)
  assert_false(c.frames[0].keyframe)
  assert_eq(c.frames[0].duration, 10)
  assert_eq(c.frames[0].data, b"\x44")
}

test "read_cluster collects ReferenceBlock dependencies from a BlockGroup" {
  // Cluster (timecode 0) with a BlockGroup: Block (track 1, tc 0, non-key,
  // "X") + two ReferenceBlocks (-40 and +33), before the Block.
  let r = @matroska.Reader::new(b"\x1F\x43\xB6\x75\x93\xE7\x81\x00\xA0\x8F\xA1\x85\x81\x00\x00\x00\x58\xFB\x82\xFF\xD8\xFB\x82\x00\x21")
  let e = @matroska.read_element(r)
  let c = @matroska.read_cluster(r, e.size.to_int())
  assert_eq(c.frames.length(), 1)
  assert_eq(c.frames[0].duration, 0)
  assert_eq(c.frames[0].references.length(), 2)
  assert_eq(c.frames[0].references[0], -40)
  assert_eq(c.frames[0].references[1], 33)
  assert_eq(c.frames[0].data, b"\x58")
}

test "read_cluster skips unknown child elements" {
  // Cluster with an unknown element (id 0xEC) before the Timecode.
  let r = @matroska.Reader::new(b"\x1F\x43\xB6\x75\x8D\xEC\x81\x00\xE7\x81\x64\xA3\x85\x81\x00\x00\x00\x45")
  let e = @matroska.read_element(r)
  let c = @matroska.read_cluster(r, e.size.to_int())
  assert_eq(c.timecode, 100)
  assert_eq(c.frames[0].data, b"\x45")
}
