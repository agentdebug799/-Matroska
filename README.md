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
- **EBML header validation** — accept the `matroska` and `webm` doctypes and
  refuse a document whose `DocTypeReadVersion` exceeds 2 (the read version
  Matroska v4 and WebM both require).
- **Segment / Info / Tracks** — the top-level `parse` API extracts the segment's
  timing (`Info`) and the full track table (`Tracks`), including audio and video
  track parameters.
- **Video display size** — each video track also reports its display dimensions
  and unit (`DisplayWidth` / `DisplayHeight` / `DisplayUnit`), so anamorphic
  and aspect-ratio-corrected playback is available.
- **Clusters / Blocks** — `parse` also walks every `Cluster`, decoding
  `SimpleBlock` and `BlockGroup` children into per-track frames with absolute
  timecodes and keyframe flags.
- **Block lacing** — Xiph, fixed and EBML lacing are all decoded; each frame
  reports its `lacing_index` and `lacing_count`, and laced frames share one
  timestamp (see the timing contract below).
- **Codec-private data** — each track exposes its `CodecPrivate` bytes (e.g. the
  OpusHead for `A_OPUS`).
- **Codec delay / pre-roll** — each track exposes its `CodecDelay` and
  `SeekPreRoll` in nanoseconds, so a downstream decoder can trim pre-skip and
  buffer pre-roll.
- **Frame duration** — a `Block` inside a `BlockGroup` reports its
  `BlockDuration` on every frame it produces.
- **Reference blocks** — a `BlockGroup`'s `ReferenceBlock` children are exposed
  as the frame's `references` (timecode offsets relative to the frame itself,
  negative for backward references).
- **SeekHead / Cues** — the segment's random-access indices are parsed into
  typed seek entries and cue points.

## Frame timing and the downstream contract

The demuxer's job ends at "frames with timing"; presenting them correctly is
the downstream decoder's job. The contract is:

- **Timecode units.** A `Frame.timecode` is in *ticks*:
  `cluster timecode + block relative timecode`. Convert to nanoseconds by
  multiplying by `Info.timecode_scale` (default 1,000,000 ns = 1 ms):

  `timestamp_ns = frame.timecode × info.timecode_scale`

- **Codec delay.** `Track.codec_delay` (from `CodecDelay`, e.g. Opus pre-skip)
  is the leading span in nanoseconds to discard: subtract it from the first
  frame's timestamp to get its presentation time. `Track.seek_pre_roll`
  (`SeekPreRoll`) is how much leading data a decoder must buffer.

- **Frame duration.** A `Frame.duration` is the `BlockDuration` of its
  `BlockGroup`, in ticks — `0` when absent, in which case the decoder falls
  back to `Track.default_duration` or the codec's own sample count.

- **Lacing and time.** A laced block carries several frames under one
  timestamp. The demuxer hands each of them the *same* `timecode` and reports
  `lacing_index` / `lacing_count`; it does **not** invent per-frame times,
  because the 2nd..Nth frames' timestamps are a function of the codec's sample
  duration (e.g. Opus 20 ms frames, VP9 frame rate), which the container does
  not store. The decoder derives those from `lacing_index` and the codec.

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
