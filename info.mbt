///|
/// The Segment `Info` element: playback timing and tool metadata.

/// A parsed `Info` element.
pub struct Info {
  /// Nanoseconds per timecode tick (default 1,000,000).
  timecode_scale : Int
  /// Total duration in timecode ticks, or -1.0 when absent.
  duration : Double
  /// The muxing application string.
  muxing_app : String
  /// The writing application string.
  writing_app : String
  /// The segment title.
  title : String
}

/// Read an `Info` element of `size` payload bytes from `r`.
pub fn read_info(r : Reader, size : Int) -> Info raise MatroskaError {
  let end = r.pos() + size
  let mut timecode_scale = 1000000
  let mut duration = -1.0
  let mut muxing_app = ""
  let mut writing_app = ""
  let mut title = ""
  while r.pos() < end {
    let e = read_element(r)
    let n = e.size.to_int()
    if e.id == TimecodeScale {
      timecode_scale = read_uint(r, n)
    } else if e.id == Duration {
      duration = read_float(r, n)
    } else if e.id == MuxingApp {
      muxing_app = read_string(r, n)
    } else if e.id == WritingApp {
      writing_app = read_string(r, n)
    } else if e.id == Title {
      title = read_string(r, n)
    } else {
      r.skip(n)
    }
  }
  {
    timecode_scale: timecode_scale,
    duration: duration,
    muxing_app: muxing_app,
    writing_app: writing_app,
    title: title,
  }
}
