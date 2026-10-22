///|
/// End-to-end parse of a hand-built minimal Matroska document: EBML header +
/// Segment (unknown size) + Info + a single audio TrackEntry.

let minimal_mkv : Bytes =
  b"\x1A\x45\xDF\xA3\xA3\x42\x86\x81\x01\x42\xF7\x81\x01\x42\xF2\x81\x04\x42\xF3\x81\x08\x42\x82\x88\x6D\x61\x74\x72\x6F\x73\x6B\x61\x42\x87\x81\x04\x42\x85\x81\x02\x18\x53\x80\x67\xFF\x15\x49\xA9\x66\xB2\x2A\xD7\xB1\x83\x0F\x42\x40\x44\x89\x88\x41\xCD\xCD\x65\x00\x00\x00\x00\x4D\x80\x8D\x6D\x61\x74\x72\x6F\x73\x6B\x61\x2D\x64\x65\x6D\x6F\x57\x41\x8D\x6D\x61\x74\x72\x6F\x73\x6B\x61\x2D\x64\x65\x6D\x6F\x16\x54\xAE\x6B\xAD\xAE\xAB\xD7\x81\x01\x73\xC5\x81\x01\x83\x81\x02\x86\x86\x41\x5F\x4F\x50\x55\x53\x22\xB5\x9C\x83\x65\x6E\x67\x88\x81\x01\xE1\x8D\xB5\x88\x40\xE7\x70\x00\x00\x00\x00\x00\x9F\x81\x02"

test "parse extracts header, info and tracks" {
  let doc = @matroska.parse(minimal_mkv)
  assert_eq(doc.header.doctype, "matroska")
  assert_eq(doc.info.timecode_scale, 1000000)
  assert_eq(doc.info.duration, 1000000000.0)
  assert_eq(doc.info.muxing_app, "matroska-demo")
  assert_eq(doc.info.writing_app, "matroska-demo")

  assert_eq(doc.tracks.entries.length(), 1)
  let t = doc.tracks.entries[0]
  assert_eq(t.number, 1)
  assert_eq(t.uid, 1)
  assert_eq(t.track_type, 2)
  assert_eq(t.codec_id, "A_OPUS")
  assert_eq(t.language, "eng")
  assert_true(t.flag_default)

  match t.audio {
    Some(a) => {
      assert_eq(a.sampling_frequency, 48000.0)
      assert_eq(a.channels, 2)
    }
    None => assert_true(false)
  }
  match t.video {
    None => assert_true(true)
    Some(_) => assert_true(false)
  }
}

test "parse rejects a stream without a Segment" {
  let caught = try {
    let _ = @matroska.parse(b"\x1A\x45\xDF\xA3\xA3\x42\x86\x81\x01\x42\xF7\x81\x01\x42\xF2\x81\x04\x42\xF3\x81\x08\x42\x82\x88\x6D\x61\x74\x72\x6F\x73\x6B\x61\x42\x87\x81\x04\x42\x85\x81\x02")
    false
  } catch {
    _ => true
  }
  assert_true(caught)
}
