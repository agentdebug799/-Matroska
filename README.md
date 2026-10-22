# matroska

A pure-MoonBit demuxer for the **Matroska / WebM** container format, built on
**EBML** (RFC 8794) with zero native dependencies.

Matroska is the container behind `.mkv` and `.webm`. This library parses its
binary structure — the EBML header, the segment's tracks and clusters, and the
individual blocks that carry audio, video and subtitle frames — and hands you
typed values instead of raw bytes.

```moonbit
let doc = @matroska.parse(data)   // Bytes -> Document
println(doc.header.doctype)       // "matroska" or "webm"
println(doc.info.timecode_scale)  // nanoseconds per timecode tick
for t in doc.tracks.entries {
  // t.codec_id, t.track_type, t.audio, t.video, ...
}
```

## What works today

- **EBML VINT** — decode/encode the 1–8 byte variable-length integers that carry
  every element ID and size, including the reserved "unknown size" marker.
- **Big-endian reader** — a cursor with `read_u8`…`read_u64`, `read_bytes` and
  bounds checking that raises `MatroskaError` instead of overflowing.
- **Element headers** — split a stream into `{ id, size, header_len }`, with the
  full Matroska/WebM element-ID table.
- **Payload decoders** — unsigned integers, UTF-8 strings and IEEE 754 floats
  (binary32 and binary64).
- **EBML header validation** — reject unknown doctypes and malformed headers.
- **Segment / Info / Tracks** — the top-level `parse` API extracts the segment's
  timing (`Info`) and the full track table (`Tracks`), including audio and video
  track parameters.
- **Clusters / Blocks** — `parse` also walks every `Cluster`, decoding
  `SimpleBlock` and `BlockGroup` children into per-track frames with absolute
  timecodes and keyframe flags.
- **Block lacing** — Xiph, fixed and EBML lacing are all decoded, so a single
  block that carries several frames is split into its constituent frames.
- **Codec-private data** — each track exposes its `CodecPrivate` bytes (e.g. the
  OpusHead for `A_OPUS`).
- **Frame duration** — a `Block` inside a `BlockGroup` reports its
  `BlockDuration` on every frame it produces.
- **SeekHead / Cues** — the segment's random-access indices are parsed into
  typed seek entries and cue points.

## Run the demo

```
moon run examples
```

It parses a hand-built Matroska document and prints its doctype, timing, and
track table.

The test suite also includes a regression that parses a real, ffmpeg-authored
WebM (Lavf60.16.100): one VP9 video track (854×480) plus one Opus audio track
(48 kHz, 2 ch), and its first cluster frame.

## Module map

| File | Responsibility |
| --- | --- |
| `error.mbt` | `MatroskaError` error type |
| `reader.mbt` | big-endian byte cursor |
| `vint.mbt` | EBML variable-length integers |
| `ebml.mbt` | element headers + element-ID table |
| `payload.mbt` | unsigned-int / string / float payload decoders |
| `header.mbt` | EBML header parsing and validation |
| `info.mbt` | `Info` element |
| `tracks.mbt` | `Tracks` / `TrackEntry` / `Video` / `Audio` |
| `block.mbt` | `Block` / `SimpleBlock` + lacing (Xiph / fixed / EBML) |
| `cluster.mbt` | `Cluster` / `Frame` extraction |
| `seek.mbt` | `SeekHead` / `SeekEntry` index |
| `cues.mbt` | `Cues` / `CuePoint` / `CueTrackPosition` |
| `matroska.mbt` | top-level `parse` API |

## Roadmap

- [x] EBML header validation (DocType, version bounds)
- [x] Segment / Info / Tracks traversal
- [x] Cluster + SimpleBlock / BlockGroup frame extraction
- [x] Block lacing (Xiph / fixed / EBML)
- [x] SeekHead-based random access
- [x] Cues seek points

## License

Apache-2.0.
