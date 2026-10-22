///|
/// The Segment `Tracks` element: the list of audio/video/subtitle tracks.

/// A video track's pixel dimensions.
pub struct Video {
  pixel_width : Int
  pixel_height : Int
}

/// An audio track's format.
pub struct Audio {
  /// Sampling frequency in Hz.
  sampling_frequency : Double
  channels : Int
  bit_depth : Int
}

/// A single `TrackEntry`.
pub struct Track {
  number : Int
  uid : Int
  /// 1 = video, 2 = audio, 17 = subtitle, ...
  track_type : Int
  /// The codec identifier, e.g. "V_VP8" or "A_OPUS".
  codec_id : String
  /// Codec-private initialization data (e.g. the OpusHead for A_OPUS), empty
  /// when the track has none.
  codec_private : Bytes
  language : String
  flag_enabled : Bool
  flag_default : Bool
  flag_lacing : Bool
  /// Default frame duration in nanoseconds (0 when absent).
  default_duration : Int
  video : Option[Video]
  audio : Option[Audio]
}

/// A parsed `Tracks` element.
pub struct Tracks {
  entries : Array[Track]
}

/// Read a `Tracks` element of `size` payload bytes from `r`.
pub fn read_tracks(r : Reader, size : Int) -> Tracks raise MatroskaError {
  let end = r.pos() + size
  let entries : Array[Track] = []
  while r.pos() < end {
    let e = read_element(r)
    if e.id == TrackEntry {
      entries.push(read_track_entry(r, e.size.to_int()))
    } else {
      r.skip(e.size.to_int())
    }
  }
  { entries: entries }
}

/// Read a single `TrackEntry` of `size` payload bytes.
fn read_track_entry(r : Reader, size : Int) -> Track raise MatroskaError {
  let end = r.pos() + size
  let mut number = 0
  let mut uid = 0
  let mut track_type = 0
  let mut codec_id = ""
  let mut codec_private = b""
  let mut language = "eng"
  let mut flag_enabled = true
  let mut flag_default = true
  let mut flag_lacing = true
  let mut default_duration = 0
  let mut video : Option[Video] = None
  let mut audio : Option[Audio] = None
  while r.pos() < end {
    let e = read_element(r)
    let n = e.size.to_int()
    if e.id == TrackNumber {
      number = read_uint(r, n)
    } else if e.id == TrackUID {
      uid = read_uint(r, n)
    } else if e.id == TrackType {
      track_type = read_uint(r, n)
    } else if e.id == CodecID {
      codec_id = read_string(r, n)
    } else if e.id == CodecPrivate {
      codec_private = r.read_bytes(n)
    } else if e.id == Language {
      language = read_string(r, n)
    } else if e.id == FlagEnabled {
      flag_enabled = read_uint(r, n) != 0
    } else if e.id == FlagDefault {
      flag_default = read_uint(r, n) != 0
    } else if e.id == FlagLacing {
      flag_lacing = read_uint(r, n) != 0
    } else if e.id == DefaultDuration {
      default_duration = read_uint(r, n)
    } else if e.id == Video {
      video = Some(read_video(r, n))
    } else if e.id == Audio {
      audio = Some(read_audio(r, n))
    } else {
      r.skip(n)
    }
  }
  {
    number: number,
    uid: uid,
    track_type: track_type,
    codec_id: codec_id,
    codec_private: codec_private,
    language: language,
    flag_enabled: flag_enabled,
    flag_default: flag_default,
    flag_lacing: flag_lacing,
    default_duration: default_duration,
    video: video,
    audio: audio,
  }
}

/// Read a `Video` element of `size` payload bytes.
fn read_video(r : Reader, size : Int) -> Video raise MatroskaError {
  let end = r.pos() + size
  let mut pixel_width = 0
  let mut pixel_height = 0
  while r.pos() < end {
    let e = read_element(r)
    let n = e.size.to_int()
    if e.id == PixelWidth {
      pixel_width = read_uint(r, n)
    } else if e.id == PixelHeight {
      pixel_height = read_uint(r, n)
    } else {
      r.skip(n)
    }
  }
  { pixel_width: pixel_width, pixel_height: pixel_height }
}

/// Read an `Audio` element of `size` payload bytes.
fn read_audio(r : Reader, size : Int) -> Audio raise MatroskaError {
  let end = r.pos() + size
  let mut sampling_frequency = 0.0
  let mut channels = 0
  let mut bit_depth = 0
  while r.pos() < end {
    let e = read_element(r)
    let n = e.size.to_int()
    if e.id == SamplingFrequency {
      sampling_frequency = read_float(r, n)
    } else if e.id == Channels {
      channels = read_uint(r, n)
    } else if e.id == BitDepth {
      bit_depth = read_uint(r, n)
    } else {
      r.skip(n)
    }
  }
  {
    sampling_frequency: sampling_frequency,
    channels: channels,
    bit_depth: bit_depth,
  }
}
