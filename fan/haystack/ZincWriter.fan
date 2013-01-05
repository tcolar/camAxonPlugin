//
// Copyright (c) 2009, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   07 Oct 09  Brian Frank  Creation
//   28 Dec 09  Brian Frank  DataWriter => ZincWriter
//

**
** ZincWriter serializes Grids to an output stream.
** See [docSkyspark]`docSkySpark::Zinc`
**
@Js
class ZincWriter : GridWriter
{
  Str zincVersion

//////////////////////////////////////////////////////////////////////////
// Convenience
//////////////////////////////////////////////////////////////////////////

  **
  ** Format a grid to a zinc string in memory.
  **
  static Str gridToStr(Grid grid, Str version)
  {
    buf := StrBuf()
    ZincWriter(buf.out, version).writeGrid(grid)
    return buf.toStr
  }

  **
  ** Format a set of tags to a string in memory which can be parsed with
  ** `ZincReader.readTags`.  The tags can be a 'Dict' or a 'Str:Obj' map.
  **
  static Str tagsToStr(Obj tags)
  {
    buf := StrBuf()
    func := |Obj? val, Str name|
    {
      if (!buf.isEmpty) buf.addChar(' ')
      buf.add(name)
      try
        if (val !== Marker.val) buf.addChar(':').add(scalarToStr(val))
      catch (Err e)
        throw IOErr("Cannot write tag $name; $e.msg")
    }
    if (tags is Dict) ((Dict)tags).each(func)
    else ((Map)tags).each(func)
    return buf.toStr
  }

  **
  ** Get a scalar value as a zinc string.
  **
  static Str scalarToStr(Obj? val)
  {
    // null
    if (val == null) return "N"

    // map to a Kind
    t := val.typeof
    kind := Kind.fromType(t, false) ?: throw IOErr("Not a valid scalar type: $t")

    return kind.valToZinc(val)
  }

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  ** Wrap given output stream
  new make(OutStream out, Str zincVersion) { this.out = out; this.zincVersion = zincVersion }

//////////////////////////////////////////////////////////////////////////
// Public
//////////////////////////////////////////////////////////////////////////

  ** Write a list of grids to stream
  override This writeGrids(Grid[] grids)
  {
    grids.each |grid| { writeGrid(grid) }
    return this
  }

  ** Write a grid to stream
  override This writeGrid(Grid grid)
  {
    // set meta-data line
    out.print("ver:\"$zincVersion\"")
    writeMeta(grid.meta)
    out.writeChar('\n')

    // columns lines
    if (grid.cols.isEmpty)
    {
      // technicially this should be illegal, but
      // for robustness handle it here
      out.print("noCols\n")
    }
    else
    {
      grid.cols.each |col, i|
      {
        if (i > 0) out.writeChar(',')
        writeCol(col)
      }
      out.writeChar('\n')
    }

    // rows
    grid.each |row| { writeRow(row) }
    out.writeChar('\n')
    return this
  }

  ** Write "\n" to stream
  This nl() { out.writeChar('\n'); return this }

  ** Flush underlying stream
  This flush() { out.flush; return this }

  ** Close underlying stream
  This close() { out.close; return this }

//////////////////////////////////////////////////////////////////////////
// Helpers
//////////////////////////////////////////////////////////////////////////

  private Void writeCol(Col col)
  {
    out.print(col.name)
    writeMeta(col.meta)
  }

  private Void writeRow(Row row)
  {
    row.grid.cols.each |col, i|
    {
      if (i > 0) out.writeChar(',')
      val := row.val(col)
      try
      {
        if (val == null)
        {
          // if this is only column, then use explicit N for null
          if (i == 0 && row.grid.cols.size == 1) out.writeChar('N')
        }
        else
        {
          writeScalar(val)
        }
      }
      catch (Err e)
      {
        throw IOErr("Cannot write col '$col.name' = '$val'; $e.msg")
      }
    }
    out.writeChar('\n')
  }

  private Void writeMeta(Dict m)
  {
    m.each |v, k|
    {
      out.print(" ").print(k)
      try
        if (v != Marker.val) { out.print(":"); writeScalar(v) }
      catch (Err e)
        throw IOErr("Cannot write meta $k: $v", e)
    }
  }

  private Void writeScalar(Obj? val)
  {
    out.print(scalarToStr(val))
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private OutStream out

}