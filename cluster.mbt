///|
/// The Segment `Cluster` element: a group of timed blocks.

/// A single decoded frame with its absolute timestamp.
pub struct Frame {
  /// The track this frame belongs to.
  track_number : Int
  /// Absolute timecode in ticks (cluster timecode + block timecode).
  timecode : Int
  keyframe : Bool
  /// Frame duration in ticks, or 0 when unknown (SimpleBlocks carry no
  /// duration; a Block inside a BlockGroup reports its `BlockDuration`).
  duration : Int
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
      collect_block_frames(r, n, timecode, 0, frames)
    } else if e.id == BlockGroup {
      read_block_group(r, n, timecode, frames)
    } else {
      r.skip(n)
    }
  }
  { timecode: timecode, frames: frames }
}

/// Expand one Block/SimpleBlock into its frames and append them.
fn collect_block_frames(r : Reader, size : Int, cluster_timecode : Int, duration : Int, frames : Array[Frame]) -> Unit raise MatroskaError {
  let b = read_block(r, size)
  let mut i = 0
  while i < b.frames.length() {
    frames.push({
      track_number: b.track_number,
      timecode: cluster_timecode + b.timecode,
      keyframe: b.keyframe,
      duration: duration,
      data: b.frames[i],
    })
    i = i + 1
  }
}

/// Read a `BlockGroup` of `size` payload bytes, extracting its Block.
///
/// Children are collected first so the `BlockDuration` is known regardless of
/// whether it precedes or follows the `Block`, then the block is decoded.
fn read_block_group(r : Reader, size : Int, cluster_timecode : Int, frames : Array[Frame]) -> Unit raise MatroskaError {
  let end = r.pos() + size
  let mut duration = 0
  let mut block_bytes : Option[Bytes] = None
  while r.pos() < end {
    let e = read_element(r)
    let n = e.size.to_int()
    if e.id == Block {
      block_bytes = Some(r.read_bytes(n))
    } else if e.id == BlockDuration {
      duration = read_uint(r, n)
    } else {
      r.skip(n) // ReferenceBlock, ...
    }
  }
  match block_bytes {
    Some(b) => {
      let br = Reader::new(b)
      collect_block_frames(br, b.length(), cluster_timecode, duration, frames)
    }
    None => ()
  }
}
