//
// Copyright (c) 2012, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   19 Aug 12  Brian Frank  Creation
//

**
** GridWriter is the interface for writing an encoding of grid data.
** All implementations must have a constructor 'make(OutStream)'
**
@Js
mixin GridWriter
{

  **
  ** Find the GridWriter type to use for the given mime type.  GridWriters
  ** are registered on a mime type using indexed props:
  **
  **   // template
  **   haystack.grid.writer.mime.{mime}={qname}
  **
  **   // example
  **   haystack.grid.writer.mime.text/zinc=haystack::ZincWriter
  **
  ** Given a type, you can construct a new writer as follows:
  **
  **   GridWriter.fromMime(mime).make([out])
  **
  static Type? fromMime(MimeType mime, Bool checked := true)
  {
    key := "haystack.grid.writer.mime.${mime.mediaType}/${mime.subType}"
    qname := Env.cur.index(key).first
    if (qname != null) return Type.find(qname)
    if (!checked) return null
    throw Err("No GridWriter registered for '$mime'")
  }

  **
  ** Write a single grid
  **
  abstract This writeGrid(Grid grid)

  **
  ** Write a list of grids
  **
  abstract This writeGrids(Grid[] grids)

}