///|
/// EBML element header (RFC 8794 §5) and the Matroska/WebM element IDs the
/// demuxer understands.

/// An EBML element header: its ID, data size, and header size in bytes.
pub struct Element {
  /// The element ID, as the raw marker-including bytes (e.g. `0x1A45DFA3` for
  /// the EBML header). Matroska element IDs are at most 4 bytes, so this fits
  /// in an `Int`.
  id : Int
  /// The data size in bytes. Meaningless when `unknown_size` is true.
  size : UInt64
  /// True when the element used the reserved "unknown size" marker.
  unknown_size : Bool
  /// Bytes occupied by the ID and size VINTs (the header itself).
  header_len : Int
}

/// Read one element header from `r`.
pub fn read_element(r : Reader) -> Element raise MatroskaError {
  let before = r.pos
  let id_vint = read_vint(r, 4)
  let id = id_vint.raw().to_int()
  let size_vint = read_vint(r, 8)
  let size = size_vint.value
  let unknown = is_unknown(size_vint)
  { id: id, size: size, unknown_size: unknown, header_len: r.pos - before }
}

// ---------------------------------------------------------------------------
// Element IDs (raw marker-including values, per Matroska / WebM).

/// The EBML header itself.
pub const EBML : Int = 0x1A45DFA3

/// EBML document-level elements.
pub const EBMLVersion : Int = 0x4286
pub const EBMLReadVersion : Int = 0x42F7
pub const EBMLMaxIDLength : Int = 0x42F2
pub const EBMLMaxSizeLength : Int = 0x42F3
pub const DocType : Int = 0x4282
pub const DocTypeVersion : Int = 0x4287
pub const DocTypeReadVersion : Int = 0x4285

/// The single top-level Segment that holds all timed data.
pub const Segment : Int = 0x18538067

/// Top-level Segment children.
pub const SeekHead : Int = 0x114D9B74
pub const Info : Int = 0x1549A966
pub const Tracks : Int = 0x1654AE6B
pub const Cluster : Int = 0x1F43B675
pub const Cues : Int = 0x1C53BB6B
pub const Attachments : Int = 0x1941A469
pub const Chapters : Int = 0x1043A770
pub const Tags : Int = 0x1254C367

/// Info children.
pub const TimecodeScale : Int = 0x2AD7B1
pub const Duration : Int = 0x4489
pub const MuxingApp : Int = 0x4D80
pub const WritingApp : Int = 0x5741
pub const Title : Int = 0x7BA9

/// Tracks / TrackEntry children.
pub const TrackEntry : Int = 0xAE
pub const TrackNumber : Int = 0xD7
pub const TrackUID : Int = 0x73C5
pub const TrackType : Int = 0x83
pub const FlagEnabled : Int = 0xB9
pub const FlagDefault : Int = 0x88
pub const FlagLacing : Int = 0x9C
pub const CodecID : Int = 0x86
pub const CodecPrivate : Int = 0x63A2
pub const Language : Int = 0x22B59C
pub const DefaultDuration : Int = 0x23E383
pub const Video : Int = 0xE0
pub const Audio : Int = 0xE1
pub const PixelWidth : Int = 0xB0
pub const PixelHeight : Int = 0xBA
pub const SamplingFrequency : Int = 0xB5
pub const Channels : Int = 0x9F
pub const BitDepth : Int = 0x6264

/// Cluster children and block elements.
pub const ClusterTimecode : Int = 0xE7
pub const SimpleBlock : Int = 0xA3
pub const BlockGroup : Int = 0xA0
pub const Block : Int = 0xA1
pub const BlockDuration : Int = 0x9B
pub const ReferenceBlock : Int = 0xFB

/// SeekHead children.
pub const Seek : Int = 0x4DBB
pub const SeekID : Int = 0x53AB
pub const SeekPosition : Int = 0x53AC
