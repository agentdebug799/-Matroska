///|
/// Top-level API: parse a Matroska/WebM byte stream into a typed `Document`.

/// A parsed Matroska document: its EBML header, segment info and tracks.
pub struct Document {
  header : EbmlHeader
  info : Info
  tracks : Tracks
  seek_head : Option[SeekHead]
  cues : Option[Cues]
  clusters : Array[Cluster]
}

/// Parse a complete Matroska/WebM byte stream.
///
/// Reads the EBML header, then the single top-level Segment, extracting its
/// `Info`, `Tracks` and `Cluster`s. Other top-level elements (Cues, ...) are
/// skipped.
pub fn parse(data : Bytes) -> Document raise MatroskaError {
  let r = Reader::new(data)
  let header = read_ebml_header(r)
  let seg = read_element(r)
  if seg.id != Segment {
    raise InvalidEbml
  }
  let limit = if seg.unknown_size { -1 } else { r.pos() + seg.size.to_int() }
  let mut info : Option[Info] = None
  let mut tracks : Option[Tracks] = None
  let mut seek_head : Option[SeekHead] = None
  let mut cues : Option[Cues] = None
  let clusters : Array[Cluster] = []
  while r.remaining() > 0 && (limit < 0 || r.pos() < limit) {
    let e = read_element(r)
    let n = e.size.to_int()
    if e.id == Info {
      info = Some(read_info(r, n))
    } else if e.id == Tracks {
      tracks = Some(read_tracks(r, n))
    } else if e.id == SeekHead {
      seek_head = Some(read_seek_head(r, n))
    } else if e.id == Cues {
      cues = Some(read_cues(r, n))
    } else if e.id == Cluster {
      clusters.push(read_cluster(r, n))
    } else {
      r.skip(n)
    }
  }
  match (info, tracks) {
    (Some(i), Some(t)) => { header: header, info: i, tracks: t, seek_head: seek_head, cues: cues, clusters: clusters }
    _ => raise InvalidEbml
  }
}
