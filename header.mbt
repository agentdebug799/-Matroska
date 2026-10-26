///|
/// The EBML header: the first element of every Matroska/WebM file, describing
/// the document's doctype and version.

/// A parsed and validated EBML header.
pub struct EbmlHeader {
  /// The document type string, e.g. "matroska" or "webm".
  doctype : String
  /// The EBML DocTypeVersion.
  doctype_version : Int
  /// The EBML DocTypeReadVersion.
  doctype_read_version : Int
}

/// Read and validate the EBML header at the start of `r`.
///
/// Raises `InvalidHeader` if the first element is not the EBML header, or if
/// its doctype is neither "matroska" nor "webm".
pub fn read_ebml_header(r : Reader) -> EbmlHeader raise MatroskaError {
  let el = read_element(r)
  if el.id != EBML {
    raise InvalidHeader
  }
  let end = r.pos() + el.size.to_int()
  let mut doctype = ""
  let mut doctype_version = 0
  let mut doctype_read_version = 0
  while r.pos() < end {
    let e = read_element(r)
    let n = e.size.to_int()
    if e.id == DocType {
      doctype = read_string(r, n)
    } else if e.id == DocTypeVersion {
      doctype_version = read_uint(r, n)
    } else if e.id == DocTypeReadVersion {
      doctype_read_version = read_uint(r, n)
    } else {
      r.skip(n)
    }
  }
  if doctype != "matroska" && doctype != "webm" {
    raise InvalidHeader
  }
  // EBML conformance (RFC 8794): a reader must refuse a document whose
  // required read version exceeds what it implements. Matroska (v4) and WebM
  // both declare DocTypeReadVersion 2, so a higher value needs a newer reader.
  if doctype_read_version > 2 {
    raise Unsupported("DocTypeReadVersion \{doctype_read_version}")
  }
  {
    doctype: doctype,
    doctype_version: doctype_version,
    doctype_read_version: doctype_read_version,
  }
}
