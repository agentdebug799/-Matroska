///|
/// A big-endian byte cursor over an in-memory EBML/Matroska byte stream.
///
/// EBML (RFC 8794) is big-endian throughout, so this reader provides the
/// big-endian multi-byte primitives the VINT and element layers build on.

/// An immutable view over a `Bytes` buffer with a forward-only cursor.
pub struct Reader {
  buf : Bytes
  mut pos : Int
}

/// Return a new reader over `buf` starting at byte 0.
pub fn Reader::new(buf : Bytes) -> Reader {
  { buf: buf, pos: 0 }
}

/// The current byte offset.
pub fn Reader::pos(self : Reader) -> Int {
  self.pos
}

/// Number of bytes remaining from the current position.
pub fn Reader::remaining(self : Reader) -> Int {
  self.buf.length() - self.pos
}

/// True when the cursor has reached the end of the buffer.
pub fn Reader::eof(self : Reader) -> Bool {
  self.pos >= self.buf.length()
}

/// Read a single byte, advancing the cursor.
pub fn Reader::read_u8(self : Reader) -> Int raise MatroskaError {
  if self.pos >= self.buf.length() {
    raise Truncated
  }
  let b = self.buf[self.pos].to_int()
  self.pos = self.pos + 1
  b
}

/// Peek at the byte at the current position without advancing.
pub fn Reader::peek_u8(self : Reader) -> Int raise MatroskaError {
  if self.pos >= self.buf.length() {
    raise Truncated
  }
  self.buf[self.pos].to_int()
}

/// Skip `n` bytes, failing if fewer remain.
pub fn Reader::skip(self : Reader, n : Int) -> Unit raise MatroskaError {
  if self.pos + n > self.buf.length() {
    raise Truncated
  }
  self.pos = self.pos + n
}

/// Read a big-endian unsigned 16-bit integer.
pub fn Reader::read_u16(self : Reader) -> Int raise MatroskaError {
  (self.read_u8() << 8) | self.read_u8()
}

/// Read a big-endian unsigned 32-bit integer.
pub fn Reader::read_u32(self : Reader) -> Int raise MatroskaError {
  (self.read_u16() << 16) | self.read_u16()
}

/// Read a big-endian unsigned 64-bit integer.
pub fn Reader::read_u64(self : Reader) -> UInt64 raise MatroskaError {
  let hi = self.read_u32().to_uint64()
  let lo = self.read_u32().to_uint64()
  (hi << 32) | lo
}

/// Read exactly `n` bytes, advancing the cursor.
pub fn Reader::read_bytes(self : Reader, n : Int) -> Bytes raise MatroskaError {
  if self.pos + n > self.buf.length() {
    raise Truncated
  }
  let out : Array[Byte] = []
  let mut i = 0
  while i < n {
    out.push(self.buf[self.pos + i])
    i = i + 1
  }
  self.pos = self.pos + n
  Bytes::from_array(out)
}
