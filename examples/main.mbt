///|
/// Demo: parse a hand-built Matroska document (EBML header + Segment + Info +
/// one audio track) and print its structure. Run with `moon run examples`.

/// A human-readable name for a Matroska track type.
fn track_type_name(t : Int) -> String {
  if t == 1 {
    "video"
  } else if t == 2 {
    "audio"
  } else if t == 17 {
    "subtitle"
  } else {
    "type=\{t}"
  }
}

fn main {
  // A minimal Matroska document: "matroska" doctype, 1 s at timecode scale
  // 1e6, and a single Opus audio track (48 kHz, 2 channels).
  let data = b"\x1A\x45\xDF\xA3\xA3\x42\x86\x81\x01\x42\xF7\x81\x01\x42\xF2\x81\x04\x42\xF3\x81\x08\x42\x82\x88\x6D\x61\x74\x72\x6F\x73\x6B\x61\x42\x87\x81\x04\x42\x85\x81\x02\x18\x53\x80\x67\xFF\x15\x49\xA9\x66\xB2\x2A\xD7\xB1\x83\x0F\x42\x40\x44\x89\x88\x41\xCD\xCD\x65\x00\x00\x00\x00\x4D\x80\x8D\x6D\x61\x74\x72\x6F\x73\x6B\x61\x2D\x64\x65\x6D\x6F\x57\x41\x8D\x6D\x61\x74\x72\x6F\x73\x6B\x61\x2D\x64\x65\x6D\x6F\x16\x54\xAE\x6B\xAD\xAE\xAB\xD7\x81\x01\x73\xC5\x81\x01\x83\x81\x02\x86\x86\x41\x5F\x4F\x50\x55\x53\x22\xB5\x9C\x83\x65\x6E\x67\x88\x81\x01\xE1\x8D\xB5\x88\x40\xE7\x70\x00\x00\x00\x00\x00\x9F\x81\x02\x1F\x43\xB6\x75\x95\xE7\x81\x00\xA3\x87\x81\x00\x00\x80\x41\x42\x43\xA3\x87\x81\x00\x28\x00\x64\x65\x66"

  let doc = try {
    @matroska.parse(data) |> Some
  } catch {
    _ => None
  }
  match doc {
    None => println("parse failed")
    Some(d) => {
      println("== Matroska document ==")
      println("  doctype        : \{d.header.doctype}")
      println("  timecode scale : \{d.info.timecode_scale}")
      println("  duration (ns)  : \{d.info.duration}")
      println("  muxing app     : \{d.info.muxing_app}")
      println("  tracks         : \{d.tracks.entries.length()}")
      let mut i = 0
      while i < d.tracks.entries.length() {
        let t = d.tracks.entries[i]
        println("  - track \{t.number} (\{track_type_name(t.track_type)}, codec \{t.codec_id}, \{t.language})")
        match t.audio {
          Some(a) => println("      audio \{a.sampling_frequency} Hz, \{a.channels} ch")
          None => ()
        }
        match t.video {
          Some(v) => {
            let disp = if v.display_width == 0 { "" } else { " (display \{v.display_width}x\{v.display_height})" }
            println("      video \{v.pixel_width}x\{v.pixel_height}\{disp}")
          }
          None => ()
        }
        i = i + 1
      }
      println("  clusters       : \{d.clusters.length()}")
      let mut ci = 0
      while ci < d.clusters.length() {
        let c = d.clusters[ci]
        println("  - cluster @ticks \{c.timecode}, \{c.frames.length()} frames")
        let mut fi = 0
        while fi < c.frames.length() {
          let f = c.frames[fi]
          let kf = if f.keyframe { "key" } else { "" }
          println("      frame track \{f.track_number} @ticks \{f.timecode} \{kf} \{f.data.length()} bytes")
          fi = fi + 1
        }
        ci = ci + 1
      }
    }
  }
}
