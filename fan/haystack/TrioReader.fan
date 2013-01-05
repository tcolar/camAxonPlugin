//
// Copyright (c) 2010, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   21 Jun 10  Brian Frank  Creation
//

**
** TrioReader is used to read tag rec via the "Tag Record Input/Output"
** format.  See [docSkyspark]`docSkySpark::Trio`
**
@Js
class TrioReader
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  ** Wrap input stream
  new make(InStream in)
  {
    this.in = in
  }

//////////////////////////////////////////////////////////////////////////
// Public
//////////////////////////////////////////////////////////////////////////

  **
  ** Read all records from the stream and close it.
  **
  Dict[] readAllRecs()
  {
    acc := Dict[,]
    eachRec |rec| { acc.add(rec) }
    return acc
  }

  **
  ** Iterate through the entire stream reading records.
  ** The stream is guaranteed to be closed when done.
  **
  Void eachRec(|Dict| f)
  {
    try
    {
      while (true)
      {
        rec := readRec
        if (rec == null) break
        f(rec)
      }
    }
    finally in.close
  }

  **
  ** Read next record from the stream or null if at end of stream.
  **
  Dict? readRec()
  {
    tags := Str:Obj[:]

    r := readTag
    if (r == -1) return null
    while (r == 0) r = readTag
    recLineNum = lineNum
    tags[name] = val

    while (true)
    {
      r = readTag
      if (r != 1) break
      if (tags[name] != null) throw err("Duplicate tag: $name")
      tags[name] = val
    }
    if (tags.isEmpty) return null
    return Etc.makeDict(tags)
  }

//////////////////////////////////////////////////////////////////////////
// Support
//////////////////////////////////////////////////////////////////////////

  ** Return -1=end of file, 0=end of rec, 1=read ok
  private Int readTag()
  {
    // read until we get data line
    line := readLine
    while (true)
    {
      // if end of file
      if (line == null) return -1

      // if end of record
      if (line.startsWith("-")) return 0

      // if empty line or comment line
      if (line.isEmpty || line.startsWith("//") || (line[0].isSpace && line.trim.isEmpty))
      {
        line = readLine
        continue
      }

      // found data line
      break
    }

    // split into name: val
    lineNum := this.lineNum
    colon := line.index(":")
    this.name = line
    this.val  = Marker.val
    if (colon != null)
    {
      this.name = line[0..<colon].trim
      valStr := line[colon+1..-1].trim
      if (valStr.isEmpty)
      {
        if (name == "src") srcLineNum = lineNum+1
        this.val = readIndentedText
      }
      else
      {
        if (name == "src") srcLineNum = lineNum
        this.val = parseScalar(valStr)
      }
    }

    if (!Etc.isTagName(name)) throw err("Invalid name: $name", lineNum)
    return 1
  }

  private Obj parseScalar(Str s)
  {
    if (s[0].isDigit || s[0] == '-')
    {
      // old RecId syntax
      if (s.size == 17 && s[8] == '-') return Ref.fromRecIdStr(s)

      // date
      if (s.size == 10 && s[4] == '-') return Date.fromStr(s, false) ?: s

      // date time
      if (s.size > 20 && s[4] == '-') return DateTime.fromStr(s, false) ?: s

      // time (allow a bit of fudge)
      if (s.size > 3 && (s[1] == ':' || s[2] == ':'))
      {
        if (s[1] == ':') s = "0$s"
        if (s.size == 5) s = "$s:00"
        return Time.fromStr(s, false) ?: s
      }

      // try as number
      if (!s.contains(" ")) return ZincReader(s.in).readScalar
    }
    else if (s[0] == '"' || s[0] == '`')
    {
      if (s[-1] != s[0]) throw err("Invalid quoted literal: $s")
      return s.in.readObj
    }
    else if (s[0] == '@')
    {
      return Ref(s[1..-1])
    }
    else
    {
      if (s == "true")  return true
      if (s == "false") return false
      if (s == "NaN")   return Number.nan
      if (s == "INF")   return Number.posInf
    }
    return s
  }

  private Str readIndentedText()
  {
    minIndent := Int.maxVal
    lines := Str[,]
    while (true)
    {
      line := readLine
      if (line == null) break
      if (line.size > 1 && !line[0].isSpace) { pushback = line; break }
      lines.add(line.trimEnd)
      for (i:=0; i<line.size; ++i)
        if (!line[i].isSpace) { if (i < minIndent) minIndent = i; break }
    }

    s := StrBuf()
    lines.each |line, i|
    {
      strip := (line.size <= minIndent) ? "" : line[minIndent..-1]
      s.join(strip, "\n")
    }
    return s.toStr
  }

  private Str? readLine()
  {
    if (pushback != null) { s := pushback; pushback = null; return s }
    ++lineNum
    return in.readLine
  }

  private ParseErr err(Str msg, Int lineNum := this.lineNum)
  {
    ParseErr(msg + " [Line $lineNum]")
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private InStream in
  private Str? pushback
  private Int recLineNum
  private Int lineNum := 0     // cur current tag
  private Int srcLineNum := 0  // for src tag
  private Str? name
  private Obj? val
}