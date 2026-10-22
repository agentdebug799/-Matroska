///|
/// The Segment `Cues` element: seek points that map a presentation timecode to
/// a `Cluster` byte position, used for fast seeking.

/// The position of one track within a cue point.
pub struct CueTrackPosition {
  /// The track number this position applies to.
  track : Int
  /// The byte offset of the cluster from the start of the Segment.
  cluster_position : Int
  /// The block number within the cluster (0 when the cue points at the cluster).
  block_number : Int
}

/// One `CuePoint`: a timecode and the positions it resolves to.
pub struct CuePoint {
  /// The presentation timecode (in the segment's timecode scale).
  time : Int
  track_positions : Array[CueTrackPosition]
}

/// A parsed `Cues` element.
pub struct Cues {
  points : Array[CuePoint]
}

/// Read a `Cues` element of `size` payload bytes from `r`.
pub fn read_cues(r : Reader, size : Int) -> Cues raise MatroskaError {
  let end = r.pos() + size
  let points : Array[CuePoint] = []
  while r.pos() < end {
    let e = read_element(r)
    let n = e.size.to_int()
    if e.id == CuePoint {
      points.push(read_cue_point(r, n))
    } else {
      r.skip(n)
    }
  }
  { points: points }
}

/// Read a single `CuePoint` of `size` payload bytes.
fn read_cue_point(r : Reader, size : Int) -> CuePoint raise MatroskaError {
  let end = r.pos() + size
  let mut time = 0
  let positions : Array[CueTrackPosition] = []
  while r.pos() < end {
    let e = read_element(r)
    let n = e.size.to_int()
    if e.id == CueTime {
      time = read_uint(r, n)
    } else if e.id == CueTrackPositions {
      positions.push(read_cue_track_position(r, n))
    } else {
      r.skip(n)
    }
  }
  { time: time, track_positions: positions }
}

/// Read a single `CueTrackPositions` of `size` payload bytes.
fn read_cue_track_position(r : Reader, size : Int) -> CueTrackPosition raise MatroskaError {
  let end = r.pos() + size
  let mut track = 0
  let mut cluster_position = 0
  let mut block_number = 0
  while r.pos() < end {
    let e = read_element(r)
    let n = e.size.to_int()
    if e.id == CueTrack {
      track = read_uint(r, n)
    } else if e.id == CueClusterPosition {
      cluster_position = read_uint(r, n)
    } else if e.id == CueBlockNumber {
      block_number = read_uint(r, n)
    } else {
      r.skip(n)
    }
  }
  { track: track, cluster_position: cluster_position, block_number: block_number }
}
