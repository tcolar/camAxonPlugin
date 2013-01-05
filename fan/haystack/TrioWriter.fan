//
// Copyright (c) 2010, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   21 Jun 10  Brian Frank  Creation
//

**
** TrioWriter is used to write tag recs via the "Tag Record Input/Output"
** format.  See [docSkyspark]`docSkySpark::Trio`
**
@Js
class TrioWriter
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  ** Wrap output stream
  new make(OutStream out)
  {
    this.out = out
  }

//////////////////////////////////////////////////////////////////////////
// Public
//////////////////////////////////////////////////////////////////////////

  **
  ** Write separator and record.  Return this.
  **
  This writeRec(Dict rec)
  {
    out.printLine("---")

    // get names in nice order
    names := Etc.dictNames(rec)
    if (rec.has("name")) { names.moveTo("name", 0);  names.moveTo("dis", 1) }
    else { names.moveTo("dis", 0) }
    names.moveTo("src", -1)

    names.each |n|
    {
      v := rec[n]
      if (v == null) return
      if (v === Marker.val) { out.printLine(n); return }
      out.print(n).writeChar(':')
      kind := Kind.fromVal(v)
      if (kind !== Kind.str) { out.printLine(kind.valToStr(v)); return }
      str := (Str)v
      if (!str.contains("\n"))
      {
        if (useQuotes(str))
          out.printLine(str.toCode)
        else
          out.printLine(str)
      }
      else
      {
        out.printLine
        str.splitLines.each |line| { out.print("  ").printLine(line) }
      }
    }
    out.flush
    return this
  }

  private static Bool useQuotes(Str s)
  {
    if (s.isEmpty) return true
    if (s[0].isDigit) return true
    if (s[0] == '-') return true
    if (s[0] == '@') return true
    if (s == "true" || s == "false" || s == "INF" || s == "NaN") return true
    return false
  }

  **
  ** Write the list of records.  Return this.
  **
  This writeAllRecs(Dict[] recs)
  {
    recs.each |rec| { writeRec(rec) }
    return this
  }

  **
  ** Close the underlying output stream
  **
  Bool close()
  {
    out.close
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private OutStream out

}