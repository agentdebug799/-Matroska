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
