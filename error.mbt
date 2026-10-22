///|
/// Errors raised while reading or demuxing a Matroska / EBML stream.
///
/// Every parsing function in this package raises `MatroskaError`; callers can
/// either let it propagate or convert it to a `Result` with
/// `try ... catch { e => Err(e) }`.

pub(all) suberror MatroskaError {
  /// The input ended before a complete value could be read.
  Truncated

  /// An EBML variable-length integer was malformed (a zero first byte, or a
  /// length that exceeds the allowed bound).
  InvalidVint

  /// An EBML element was structurally impossible (reserved value, bad header).
  InvalidEbml

  /// The EBML header is missing, has the wrong doctype, or is malformed.
  InvalidHeader

  /// A well-formed but not-yet-supported Matroska feature was encountered.
  Unsupported(String)
}
