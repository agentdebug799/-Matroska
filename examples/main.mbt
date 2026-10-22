///|
/// Demo: parse a hand-built EBML header (the head of a tiny Matroska document)
/// and print its element tree. Run with `moon run examples`.

/// A human-readable name for the well-known EBML header elements.
fn name_of(id : Int) -> String {
  if id == @matroska.EBMLVersion {
    "EBMLVersion"
  } else if id == @matroska.EBMLReadVersion {
    "EBMLReadVersion"
  } else if id == @matroska.EBMLMaxIDLength {
    "EBMLMaxIDLength"
  } else if id == @matroska.EBMLMaxSizeLength {
    "EBMLMaxSizeLength"
  } else if id == @matroska.DocType {
    "DocType"
  } else if id == @matroska.DocTypeVersion {
    "DocTypeVersion"
  } else if id == @matroska.DocTypeReadVersion {
    "DocTypeReadVersion"
  } else {
    "id=\{id}"
  }
}

fn main {
  // EBML header: ID 1A45DFA3, size A3 (35 bytes), then the document elements.
  let data = b"\x1A\x45\xDF\xA3\xA3\x42\x86\x81\x01\x42\xF7\x81\x01\x42\xF2\x81\x04\x42\xF3\x81\x08\x42\x82\x88\x6D\x61\x74\x72\x6F\x73\x6B\x61\x42\x87\x81\x04\x42\x85\x81\x02"

  let r = @matroska.Reader::new(data)
  let _ = try {
    let hdr = @matroska.read_element(r)
    println("== EBML header (size \{hdr.size.to_int()}) ==")
    let end = r.pos() + hdr.size.to_int()
    while r.pos() < end {
      let e = @matroska.read_element(r)
      let payload = e.size.to_int()
      if e.id == @matroska.DocType {
        let s = r.read_bytes(payload)
        println("  DocType = \{@utf8.decode_lossy(s)}")
      } else {
        let mut v = 0
        let mut i = 0
        while i < payload {
          v = (v << 8) | r.read_u8()
          i = i + 1
        }
        println("  \{name_of(e.id)} = \{v}")
      }
    }
  } catch {
    _ => println("parse failed: malformed EBML header")
  }
}
