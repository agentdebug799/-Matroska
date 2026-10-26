///|
/// EBML header validation vectors.

let header_matroska : Bytes =
  b"\x1A\x45\xDF\xA3\xA3\x42\x86\x81\x01\x42\xF7\x81\x01\x42\xF2\x81\x04\x42\xF3\x81\x08\x42\x82\x88\x6D\x61\x74\x72\x6F\x73\x6B\x61\x42\x87\x81\x04\x42\x85\x81\x02"

test "read_ebml_header extracts doctype and versions" {
  let h = @matroska.read_ebml_header(@matroska.Reader::new(header_matroska))
  assert_eq(h.doctype, "matroska")
  assert_eq(h.doctype_version, 4)
  assert_eq(h.doctype_read_version, 2)
}

test "read_ebml_header accepts a webm doctype" {
  // Same layout as header_matroska but DocType = "webm" (size 0x9F = 31).
  let data = b"\x1A\x45\xDF\xA3\x9F\x42\x86\x81\x01\x42\xF7\x81\x01\x42\xF2\x81\x04\x42\xF3\x81\x08\x42\x82\x84\x77\x65\x62\x6D\x42\x87\x81\x04\x42\x85\x81\x02"
  let h = @matroska.read_ebml_header(@matroska.Reader::new(data))
  assert_eq(h.doctype, "webm")
}

test "read_ebml_header rejects an unknown doctype" {
  let data = b"\x1A\x45\xDF\xA3\xA3\x42\x86\x81\x01\x42\xF7\x81\x01\x42\xF2\x81\x04\x42\xF3\x81\x08\x42\x82\x88\x75\x6E\x6B\x6E\x6F\x77\x6E\x21\x42\x87\x81\x04\x42\x85\x81\x02"
  let caught = try {
    let _ = @matroska.read_ebml_header(@matroska.Reader::new(data))
    false
  } catch {
    _ => true
  }
  assert_true(caught)
}

test "read_ebml_header rejects a stream that is not an EBML header" {
  let caught = try {
    let _ = @matroska.read_ebml_header(@matroska.Reader::new(b"\x18\x53\x80\x67\xFF"))
    false
  } catch {
    _ => true
  }
  assert_true(caught)
}

test "read_ebml_header refuses a DocTypeReadVersion above 2" {
  // A webm header declaring DocTypeReadVersion 3: this reader implements
  // read version 2 (as Matroska v4 and WebM both require), so it refuses.
  let data = b"\x1A\x45\xDF\xA3\x8F\x42\x82\x84\x77\x65\x62\x6D\x42\x87\x81\x02\x42\x85\x81\x03"
  let caught = try {
    let _ = @matroska.read_ebml_header(@matroska.Reader::new(data))
    false
  } catch {
    _ => true
  }
  assert_true(caught)
}
