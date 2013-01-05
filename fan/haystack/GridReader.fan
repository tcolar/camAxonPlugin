//
// Copyright (c) 2012, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   19 Aug 12  Brian Frank  Creation
//

**
** GridReader is the interface for reading an encoding of grid data
** All implementations must have a constructor 'make(InStream)'.
**
@Js
mixin GridReader
{

  **
  ** Find the GridReader to use for the given mime type.  GridReaders
  ** are registered on a mime type using indexed props:
  **
  **   // template
  **   haystack.grid.reader.mime.{mime}={qname}
  **
  **   // example
  **   haystack.grid.reader.mime.text/zinc=haystack::ZincReader
  **
  ** Given a type, you can construct a new reader as follows:
  **
  **   GridReader.fromMime(mime).make([in])
  **
  static Type? fromMime(MimeType mime, Bool checked := true)
  {
    key := "haystack.grid.reader.mime.${mime.mediaType}/${mime.subType}"
    qname := Env.cur.index(key).first
    if (qname != null) return Type.find(qname)
    if (!checked) return null
    throw Err("No GridReader registered for '$mime'")
  }

  **
  ** Read a single grid
  **
  abstract Grid readGrid()

  **
  ** Read a list of grids
  **
  abstract Grid[] readGrids()

}