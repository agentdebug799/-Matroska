# matroska

A pure-MoonBit demuxer for the **Matroska / WebM** container format, built on
**EBML** (RFC 8794) with zero native dependencies.

Matroska is the container behind `.mkv` and `.webm`. This library parses its
binary structure — the EBML header, the segment's tracks and clusters, and the
individual blocks that carry audio, video and subtitle frames — and hands you
typed values instead of raw bytes.

```moonbit
let r = @matroska.Reader::new(data)
let ebml = @matroska.read_element(r)          // the EBML header
let seg  = @matroska.read_element(r)          // the following Segment
// ...
```

## What works today

- **EBML VINT** — decode/encode the 1–8 byte variable-length integers that carry
  every element ID and size, including the reserved "unknown size" marker.
- **Big-endian reader** — a small cursor with `read_u8`…`read_u64`, `read_bytes`
  and bounds checking that raises `MatroskaError` instead of overflowing.
- **Element headers** — split a stream into `{ id, size, header_len }`, with the
  full Matroska/WebM element-ID table (EBML header, Segment, Info, Tracks,
  Cluster, SimpleBlock, …).

## Run the demo

```
moon run examples
```

It parses a hand-built EBML header and prints each document element by name.

## Module map

| File | Responsibility |
| --- | --- |
| `error.mbt` | `MatroskaError` error type |
| `reader.mbt` | big-endian byte cursor |
| `vint.mbt` | EBML variable-length integers |
| `ebml.mbt` | element headers + element-ID table |

## Roadmap

- [ ] EBML header validation (DocType, version bounds)
- [ ] Segment / Info / Tracks traversal
- [ ] Cluster + SimpleBlock / BlockGroup frame extraction
- [ ] Block lacing (Xiph / fixed / EBML)
- [ ] SeekHead-based random access

## License

Apache-2.0.
