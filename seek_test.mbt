///|
/// SeekHead parsing vectors.

test "read_seek_head decodes a Seek entry" {
  // SeekHead with one Seek: Info at segment position 32.
  let r = @matroska.Reader::new(b"\x11\x4D\x9B\x74\x8E\x4D\xBB\x8B\x53\xAB\x84\x15\x49\xA9\x66\x53\xAC\x81\x20")
  let e = @matroska.read_element(r)
  assert_eq(e.id, @matroska.SeekHead)
  let sh = @matroska.read_seek_head(r, e.size.to_int())
  assert_eq(sh.entries.length(), 1)
  assert_eq(sh.entries[0].id, @matroska.Info)
  assert_eq(sh.entries[0].position, 32)
}

test "read_seek_head decodes multiple Seek entries" {
  // Two Seeks: Info @ 32 and Cluster @ 200.
  let r = @matroska.Reader::new(
    b"\x11\x4D\x9B\x74\x9C\x4D\xBB\x8B\x53\xAB\x84\x15\x49\xA9\x66\x53\xAC\x81\x20" +
      b"\x4D\xBB\x8B\x53\xAB\x84\x1F\x43\xB6\x75\x53\xAC\x81\xC8",
  )
  let e = @matroska.read_element(r)
  let sh = @matroska.read_seek_head(r, e.size.to_int())
  assert_eq(sh.entries.length(), 2)
  assert_eq(sh.entries[0].id, @matroska.Info)
  assert_eq(sh.entries[0].position, 32)
  assert_eq(sh.entries[1].id, @matroska.Cluster)
  assert_eq(sh.entries[1].position, 200)
}
