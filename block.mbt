///|
/// A Matroska Block / SimpleBlock: one or more frames for a single track that
/// share a relative timestamp, optionally laced together.

/// A parsed block. SimpleBlock and the Block inside a BlockGroup share this
/// layout: track number, relative timecode, flags, optional lacing, then the
/// frame payloads.
pub struct Block {
  /// The track this block belongs to.
  track_number : Int
  /// Timecode relative to the enclosing Cluster's Timecode (in ticks).
  timecode : Int
  keyframe : Bool
  invisible : Bool
  /// Lacing type: 0 = none, 1 = Xiph, 2 = fixed, 3 = EBML.
  lacing : Int
  /// The decoded frames (one element per frame).
  frames : Array[Bytes]
}

/// Read a Block/SimpleBlock payload of `size` bytes from `r`.
pub fn read_block(r : Reader, size : Int) -> Block raise MatroskaError {
  let end = r.pos() + size
  let track_number = read_vint(r, 8).value.to_int()
  let tc = r.read_u16()
  let timecode = if tc >= 0x8000 { tc - 0x10000 } else { tc }
  let flags = r.read_u8()
  let keyframe = (flags & 0x80) != 0
  let invisible = (flags & 0x01) != 0
  let lacing = (flags >> 1) & 0x03
  let frames = read_laced_frames(r, end, lacing)
  {
    track_number: track_number,
    timecode: timecode,
    keyframe: keyframe,
    invisible: invisible,
    lacing: lacing,
    frames: frames,
  }
}

/// Read the frame payloads, splitting laced blocks into their frames.
fn read_laced_frames(r : Reader, end : Int, lacing : Int) -> Array[Bytes] raise MatroskaError {
  if lacing == 0 {
    [r.read_bytes(end - r.pos())]
  } else {
    let frame_count = r.read_u8() + 1
    let sizes = lacing_sizes(r, frame_count, lacing, end)
    read_frames_by_size(r, sizes)
  }
}

/// Compute the per-frame sizes from a lacing header.
fn lacing_sizes(r : Reader, frame_count : Int, lacing : Int, end : Int) -> Array[Int] raise MatroskaError {
  let sizes : Array[Int] = []
  let mut sum = 0
  let mut i = 0
  if lacing == 1 {
    // Xiph: frame_count - 1 explicit sizes, the last is the remainder.
    while i < frame_count - 1 {
      let mut sz = 0
      let mut b = r.read_u8()
      while b == 255 {
        sz = sz + 255
        b = r.read_u8()
      }
      sz = sz + b
      sizes.push(sz)
      sum = sum + sz
      i = i + 1
    }
    sizes.push(end - r.pos() - sum)
  } else if lacing == 2 {
    // Fixed: every frame has the same size.
    let each = (end - r.pos()) / frame_count
    while i < frame_count {
      sizes.push(each)
      i = i + 1
    }
  } else if lacing == 3 {
    // EBML: first size is unsigned, the rest are signed deltas.
    let first = read_vint(r, 8).value.to_int()
    sizes.push(first)
    sum = first
    let mut prev = first
    i = 1
    while i < frame_count {
      let delta = read_signed_vint(r)
      let sz = prev + delta
      sizes.push(sz)
      sum = sum + sz
      prev = sz
      i = i + 1
    }
  } else {
    raise InvalidEbml
  }
  sizes
}

/// Read the frames according to a pre-computed size list.
fn read_frames_by_size(r : Reader, sizes : Array[Int]) -> Array[Bytes] raise MatroskaError {
  let frames : Array[Bytes] = []
  let mut i = 0
  while i < sizes.length() {
    frames.push(r.read_bytes(sizes[i]))
    i = i + 1
  }
  frames
}

/// Read a signed VINT (EBML lacing delta): the value is two's complement in
/// the VINT's value bits.
fn read_signed_vint(r : Reader) -> Int raise MatroskaError {
  let v = read_vint(r, 8)
  let bits = 7 * v.length
  let value = v.value.to_int()
  let half = 1 << (bits - 1)
  if value >= half {
    value - (half << 1)
  } else {
    value
  }
}
