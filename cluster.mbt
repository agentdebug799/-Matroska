///|
/// The Segment `Cluster` element: a group of timed blocks.

/// A single decoded frame with its absolute timestamp.
pub struct Frame {
  /// The track this frame belongs to.
  track_number : Int
  /// Absolute timecode in ticks (cluster timecode + block timecode).
  timecode : Int
  keyframe : Bool
  /// The raw frame payload.
  data : Bytes
}

/// A parsed `Cluster` element.
pub struct Cluster {
  /// Absolute cluster timecode in ticks.
  timecode : Int
  /// The frames in this cluster, in order.
  frames : Array[Frame]
}

/// Read a `Cluster` element of `size` payload bytes from `r`.
pub fn read_cluster(r : Reader, size : Int) -> Cluster raise MatroskaError {
  let end = r.pos() + size
  let mut timecode = 0
  let frames : Array[Frame] = []
  while r.pos() < end {
    let e = read_element(r)
    let n = e.size.to_int()
    if e.id == ClusterTimecode {
      timecode = read_uint(r, n)
    } else if e.id == SimpleBlock {
      collect_block_frames(r, n, timecode, frames)
    } else if e.id == BlockGroup {
      read_block_group(r, n, timecode, frames)
    } else {
      r.skip(n)
    }
  }
  { timecode: timecode, frames: frames }
}

/// Expand one Block/SimpleBlock into its frames and append them.
fn collect_block_frames(r : Reader, size : Int, cluster_timecode : Int, frames : Array[Frame]) -> Unit raise MatroskaError {
  let b = read_block(r, size)
  let mut i = 0
  while i < b.frames.length() {
    frames.push({
      track_number: b.track_number,
      timecode: cluster_timecode + b.timecode,
      keyframe: b.keyframe,
      data: b.frames[i],
    })
    i = i + 1
  }
}

/// Read a `BlockGroup` of `size` payload bytes, extracting its Block.
fn read_block_group(r : Reader, size : Int, cluster_timecode : Int, frames : Array[Frame]) -> Unit raise MatroskaError {
  let end = r.pos() + size
  while r.pos() < end {
    let e = read_element(r)
    let n = e.size.to_int()
    if e.id == Block {
      collect_block_frames(r, n, cluster_timecode, frames)
    } else {
      r.skip(n) // BlockDuration, ReferenceBlock, ...
    }
  }
}
