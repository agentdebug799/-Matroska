///|
/// The Segment `SeekHead` element: an index of byte offsets to the top-level
/// elements (Info, Tracks, Clusters, Cues, ...) for random access.

/// One `Seek` entry: a top-level element ID and its byte position.
pub struct SeekEntry {
  /// The target element ID (raw marker-including value, e.g. `0x1549A966`).
  id : Int
  /// The byte offset of the target element from the start of the Segment.
  position : Int
}

/// A parsed `SeekHead` element.
pub struct SeekHead {
  entries : Array[SeekEntry]
}

/// Read a `SeekHead` element of `size` payload bytes from `r`.
pub fn read_seek_head(r : Reader, size : Int) -> SeekHead raise MatroskaError {
  let end = r.pos() + size
  let entries : Array[SeekEntry] = []
  while r.pos() < end {
    let e = read_element(r)
    let n = e.size.to_int()
    if e.id == Seek {
      entries.push(read_seek_entry(r, n))
    } else {
      r.skip(n)
    }
  }
  { entries: entries }
}

/// Read a single `Seek` element of `size` payload bytes.
fn read_seek_entry(r : Reader, size : Int) -> SeekEntry raise MatroskaError {
  let end = r.pos() + size
  let mut id = 0
  let mut position = 0
  while r.pos() < end {
    let e = read_element(r)
    let n = e.size.to_int()
    if e.id == SeekID {
      // SeekID's payload is the raw ID bytes of the target element.
      let br = Reader::new(r.read_bytes(n))
      id = read_vint(br, 4).raw().to_int()
    } else if e.id == SeekPosition {
      position = read_uint(r, n)
    } else {
      r.skip(n)
    }
  }
  { id: id, position: position }
}
