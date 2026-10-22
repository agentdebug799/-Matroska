///|
/// Element header parsing against a hand-built EBML header.

test "read_element parses the EBML header ID and size" {
  // EBML element: ID 1A 45 DF A3, size A3 (=35), payload follows.
  let r = @matroska.Reader::new(b"\x1A\x45\xDF\xA3\xA3")
  let e = @matroska.read_element(r)
  assert_eq(e.id, @matroska.EBML)
  assert_eq(e.size.to_int(), 35)
  assert_false(e.unknown_size)
  assert_eq(e.header_len, 5)
}

test "read_element flags the unknown-size marker" {
  // Segment element with a 1-byte unknown size (0xFF).
  let e = @matroska.read_element(@matroska.Reader::new(b"\x18\x53\x80\x67\xFF"))
  assert_eq(e.id, @matroska.Segment)
  assert_true(e.unknown_size)
}

test "walks a complete EBML header and reads the DocType" {
  let data = b"\x1A\x45\xDF\xA3\xA3\x42\x86\x81\x01\x42\xF7\x81\x01\x42\xF2\x81\x04\x42\xF3\x81\x08\x42\x82\x88\x6D\x61\x74\x72\x6F\x73\x6B\x61\x42\x87\x81\x04\x42\x85\x81\x02"
  let r = @matroska.Reader::new(data)
  let hdr = @matroska.read_element(r)
  assert_eq(hdr.id, @matroska.EBML)
  assert_eq(hdr.size.to_int(), 35)
  let end = r.pos() + hdr.size.to_int()
  let mut doctype = b""
  let versions : Array[Int] = []
  while r.pos() < end {
    let e = @matroska.read_element(r)
    let payload = e.size.to_int()
    if e.id == @matroska.DocType {
      doctype = r.read_bytes(payload)
    } else {
      let mut v = 0
      let mut i = 0
      while i < payload {
        v = (v << 8) | r.read_u8()
        i = i + 1
      }
      versions.push(v)
    }
  }
  assert_eq(doctype, b"\x6D\x61\x74\x72\x6F\x73\x6B\x61")
  assert_eq(versions.length(), 6)
  assert_eq(versions[0], 1) // EBMLVersion
  assert_eq(versions[1], 1) // EBMLReadVersion
  assert_eq(versions[2], 4) // EBMLMaxIDLength
  assert_eq(versions[3], 8) // EBMLMaxSizeLength
  assert_eq(versions[4], 4) // DocTypeVersion
  assert_eq(versions[5], 2) // DocTypeReadVersion
}

test "element ID constants are their raw marker-including values" {
  assert_eq(@matroska.EBML, 0x1A45DFA3)
  assert_eq(@matroska.Segment, 0x18538067)
  assert_eq(@matroska.Info, 0x1549A966)
  assert_eq(@matroska.Cluster, 0x1F43B675)
  assert_eq(@matroska.Tracks, 0x1654AE6B)
  assert_eq(@matroska.DocType, 0x4282)
  assert_eq(@matroska.TrackEntry, 0xAE)
  assert_eq(@matroska.SimpleBlock, 0xA3)
}
