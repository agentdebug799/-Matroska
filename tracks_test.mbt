///|
/// Tracks parsing vectors.

test "read_tracks extracts video display size" {
  // Tracks with one TrackEntry: a 1920x1080 V_VP9 video whose display size
  // (DisplayWidth/DisplayHeight) matches the pixels and DisplayUnit is 3.
  let r = @matroska.Reader::new(b"\x16\x54\xAE\x6B\xA7\xAE\xA5\xD7\x81\x01\x83\x81\x01\x86\x85\x56\x5F\x56\x50\x39\xE0\x96\xB0\x82\x07\x80\xBA\x82\x04\x38\x54\xB0\x82\x07\x80\x54\xBA\x82\x04\x38\x54\xB2\x81\x03")
  let e = @matroska.read_element(r)
  assert_eq(e.id, @matroska.Tracks)
  let t = @matroska.read_tracks(r, e.size.to_int())
  assert_eq(t.entries.length(), 1)
  let tr = t.entries[0]
  assert_eq(tr.number, 1)
  assert_eq(tr.track_type, 1)
  assert_eq(tr.codec_id, "V_VP9")
  match tr.video {
    Some(v) => {
      assert_eq(v.pixel_width, 1920)
      assert_eq(v.pixel_height, 1080)
      assert_eq(v.display_width, 1920)
      assert_eq(v.display_height, 1080)
      assert_eq(v.display_unit, 3)
    }
    None => assert_true(false)
  }
}

test "read_tracks exposes CodecDelay and SeekPreRoll" {
  // One TrackEntry with CodecDelay = 6500000 ns (Opus pre-skip) and
  // SeekPreRoll = 80000000 ns. The demuxer surfaces both so a downstream
  // decoder can trim the first samples and buffer pre-roll.
  let r = @matroska.Reader::new(b"\x16\x54\xAE\x6B\x9A\xAE\x98\xD7\x81\x01\x86\x86\x41\x5F\x4F\x50\x55\x53\x56\xAA\x83\x63\x2E\xA0\x56\xBB\x84\x04\xC4\xB4\x00")
  let e = @matroska.read_element(r)
  assert_eq(e.id, @matroska.Tracks)
  let t = @matroska.read_tracks(r, e.size.to_int())
  assert_eq(t.entries[0].codec_delay, 6500000)
  assert_eq(t.entries[0].seek_pre_roll, 80000000)
}
