//
// Copyright (c) 2009, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   06 Jun 09  Brian Frank  Creation
//   28 Dec 09  Brian Frank  DataReader => ZincReader
//

**
** ZincReader deserializes Grids from an input stream.
** See [docSkyspark]`docSkySpark::Zinc`
**
@Js
class ZincReader : GridReader
{

//////////////////////////////////////////////////////////////////////////
// Constructor
//////////////////////////////////////////////////////////////////////////

  ** Wrap input stream
  new make(InStream in)
  {
    this.in   = in
    this.cur  = readChar
    this.peek = readChar
    consumeToken
  }

//////////////////////////////////////////////////////////////////////////
// Public
//////////////////////////////////////////////////////////////////////////

  **
  ** Read a grid from stream.
  **
  override Grid readGrid()
  {
    readVer
    meta := readMeta; consumeNewline
    cols := readCols
    set  := ZincGrid(meta, cols)
    readRows(set)
    return set
  }

  **
  ** Read a list of grids separated by blank line from stream.
  **
  override Grid[] readGrids()
  {
    grids := Grid[,]
    while (tok == identifier)
      grids.add(readGrid)
    return grids
  }

  **
  ** Read a set of tags as name/value pairs formatted as "name: val"
  ** separated by space.  I val is omitted, then Marker.val is assumed.
  ** This is the same as the Zinc 'meta' production.
  ** Also see `ZincWriter.tagsToStr`.
  **
  Dict readTags()
  {
    readMeta
  }

  **
  ** Read scalar value: Bool, Int, Str, Uri, etc
  ** Also see `ZincWriter.scalarToStr`.
  **
  Obj readScalar()
  {
    consumeScalar
  }

  ** Close the underlying stream.
  Bool close() { in.close }

//////////////////////////////////////////////////////////////////////////
// Implementation
//////////////////////////////////////////////////////////////////////////

  private Void readVer()
  {
    verifyId("ver")
    consumeToken
    verify(':')
    consumeToken
    if (val == "2.0") version = 2
    else if (val == "1.0") version = 1
    else throw IOErr("Unsupported version: $val")
    consumeToken
  }

  internal Dict readMeta()
  {
    [Str:Obj?]? map := null
    while (tok != ',' && tok != '}' && tok != newline && tok != eof)
    {
      if (map == null) map = Str:Obj?[:]
      Str key := consumeId
      Obj? val := Marker.val
      if (tok == ':')
      {
        consumeToken
        val = consumeScalar
      }
      map.add(key, val)
    }
    return map == null ? Etc.emptyDict : Etc.makeDict(map)
  }

  private ZincCol[] readCols()
  {
    cols := ZincCol[,]
    while (true)
    {
      cols.add(readCol(cols.size))
      if (tok == ',') { consumeToken; continue }
      if (tok != eof) consumeNewline
      break
    }
    return cols
  }

  private ZincCol readCol(Int index)
  {
    name := consumeId
    Str? dis := null
    if (tok == scalar && val is Str)
    {
      dis = consumeScalar
      if (version >= 2) throw Err("Invalid col dis in 2.0 grid: $name")
    }
    meta := readMeta
    if (dis != null) meta = Etc.dictSet(meta, "dis", dis)
    return ZincCol(name, meta)
  }

  private Void readRows(ZincGrid grid)
  {
    numCols := grid.cols.size
    while (tok != newline && tok != eof)
      grid.rows.add(readRow(grid, numCols))
    if (tok != eof) consumeNewline
  }

  private ZincRow readRow(ZincGrid grid, Int numCols)
  {
    cells := Obj?[,]
    cells.capacity = numCols
    for (i:=1; i<numCols; ++i)
    {
      cells.add(readCell)
      verify(',')
      consumeToken
    }
    cells.add(readCell)
    if (tok != eof) consumeNewline
    return ZincRow(grid.ref, cells)
  }

  private Obj? readCell()
  {
    if (tok == ',' || tok == newline || tok == eof) return null
    val := consumeScalar
    Str? dis := null
    if (tok == scalar && this.val is Str) dis = consumeScalar
    meta := readMeta
    if (dis == null && meta.isEmpty) return val
    if (version >= 2) throw Err("Invalid cell dis/meta in 2.0 grid: $dis $meta")
    return val
  }

//////////////////////////////////////////////////////////////////////////
// Diff
//////////////////////////////////////////////////////////////////////////

  // Must be in-sync with proj::Diff (we mask with force flag)
  private static const Int diffUpdate := 0x08
  private static const Int diffAdd    := 0x01.or(0x08)
  private static const Int diffRemove := 0x02.or(0x08)

  **
  ** Support to read proj::Diff - nust override makeDiff
  **
  @NoDoc Obj? readDiff()
  {
    // skip comment line
    while (tok == '#') skipLine

    if (tok == eof) return null

    flags := 0
    switch (tok)
    {
      case '^': flags = diffUpdate
      case '+': flags = diffAdd
      case '-': flags = diffRemove
      default:  throw err("Expected diff ^ + - , not ${tokenType(tok)}")
    }
    consumeToken

    verify('{')
    consumeToken

    if (consumeId != "id") throw Err()
    verify(':')
    consumeToken
    Ref id := consumeScalar
    verify(',')
    consumeToken

    if (consumeId != "mod") throw Err()
    verify(':')
    consumeToken
    DateTime mod := consumeScalar

    changes := Str:Obj?[:]
    while(tok == ',')
    {
      consumeToken
      name := parseTagName(consumeId)
      Obj? val := Marker.val
      if (tok == ':')
      {
        consumeToken
        val = consumeScalar
      }
      changes[name] = val
    }
    if (tok != '}') throw err("Expecting } end of diff, not ${tokenType(tok)}")
    consumeToken
    if (tok != newline) throw err("Expecting newline, not ${tokenType(tok)}")
    consumeToken

    return makeDiff(id, mod, Etc.makeDict(changes), flags)
  }

  @NoDoc virtual Obj makeDiff(Ref id, DateTime mod, Dict changes, Int flags)
  {
    throw UnsupportedErr()
  }

//////////////////////////////////////////////////////////////////////////
// Tokenizing
//////////////////////////////////////////////////////////////////////////

  **
  ** Read the next token, store result in `tok` and `val`:
  **
  **   tok          val
  **   ------       -----
  **   symbol       null
  **   identifier   Str
  **   literal      Bool, Int, Float, Str, Uri
  **
  private Int consumeToken()
  {
    // reset
    val = null

    // skip whitespace or comments
    while (cur.isSpace || cur == '/')
    {
      if (cur == '\n') { ++line; consumeChar; return tok = newline }
      if (cur == '/') consumeComment
      else consumeChar
    }

    // handle various starting chars
    if (cur == 'B')  return consumeBin
    if (cur == 'C')  return consumeCoor
    if (cur.isAlpha) return consumeWord
    if (cur == '"')  return consumeStr
    if (cur == '@')  return consumeRef
    if (cur.isDigit || (cur == '-' && peek.isDigit)) return consumeNum
    if (cur == '-' && peek == 'I') return consumeWord
    if (cur == '`')  return consumeUri

    // symbol
    tok = cur; consumeChar
    return tok
  }

  private Void verify(Int expected)
  {
    if (tok != expected) throw err("Expecting ${tokenType(expected)}, not ${tokenType(tok)} ($val)")
  }

  private Void verifyId(Str id)
  {
    if (tok != identifier) throw err("Expecting identifier, not ${tokenType(tok)}")
    if (id != val) throw err("Expecting $id, not $val")
  }

  internal Str consumeId() { verify(identifier); x := val; consumeToken; return x }

  private Obj? consumeScalar() { verify(scalar); x := val; consumeToken; return x }

  private Void consumeNewline() { verify(newline); consumeToken }

  private Void consumeSymbol(Int symbol) { verify(symbol); consumeToken }

  private Int consumeWord()
  {
    // parse xxx-xxx and keep track of dashes
    s := StrBuf().addChar(cur)
    consumeChar
    while (cur.isAlphaNum || cur == '_')
    {
      s.addChar(cur)
      consumeChar
    }

    // if lowercase it is an identifier
    id := s.toStr
    if (id[0].isLower) { val = id; return tok = identifier }

    // otherwise must be keyword
    switch (id)
    {
      case "T":    val = true;  return tok = scalar
      case "F":    val = false; return tok = scalar
      case "N":    val = null;  return tok = scalar
      case "M":    val = Marker.val; return tok = scalar
      case "R":    val = Remove.val; return tok = scalar
      case "NaN":  val = Number.nan; return tok = scalar
      case "INF":  val = Number.posInf; return tok = scalar
      case "-INF": val = Number.negInf; return tok = scalar
      default:     throw err("Unknown keyword $id")
    }
  }

  private Int consumeBin()
  {
    // Bin
    consumeBinChars("Bin")

    // Version 2.0: Bin(text/plain)
    mime := Bin.defVal.mime.toStr
    if (cur == '(')
    {
      consumeChar
      s := StrBuf()
      while (cur != ')' && cur > 0)
      {
        s.addChar(cur)
        consumeChar
      }
      consumeChar
      mime = s.toStr
    }

    // Version 1.0: Bin mime:"text/plain"
    else
    {
      if (version >= 2) throw Err("Expecting 2.0 Bin(mime) syntax")
      consumeBinChars(" mime:\"")
      s := StrBuf()
      while (cur != '"' && cur > 0)
      {
        s.addChar(cur)
        consumeChar
      }
      consumeChar
      mime = s.toStr
    }

    val = parseBin(mime)
    return tok = scalar
  }

  private Void consumeBinChars(Str expected)
  {
    for (i:=0; i<expected.size; ++i)
    {
      expectedChar := expected[i]
      if (cur != expectedChar) throw err("Expecting Bin '$expected'; '$expectedChar.toChar' != '$cur.toChar'")
      consumeChar
    }
  }

  private Int consumeCoor()
  {
    s := StrBuf()
    while (cur != ')')
    {
      s.addChar(cur)
      consumeChar
    }
    s.addChar(cur)
    consumeChar

    val = parseCoord(s.toStr)
    return tok = scalar
  }

  private Int consumeNum()
  {
    s := StrBuf().addChar(cur);
    consumeChar

    // digits | - | + | _ | : | .
    colons := 0; dashes := 0; exp := false
    unitIndex := 0
    while (true)
    {
      if (!cur.isDigit)
      {
        if (cur == '-') dashes++
        else if (cur == ':') colons++
        else if ((cur == 'e' || cur == 'E') && (peek == '-' || peek == '+' || peek.isDigit)) exp = true
        else if (cur.isAlpha || cur > 128 || cur == '/' || cur == '%' || cur == '$') { if (unitIndex == 0) unitIndex = s.size }
        else if (cur == '_') { if (unitIndex == 0 && peek.isDigit) { consumeChar; continue } else { if (unitIndex == 0) unitIndex = s.size } }
        else if (cur != '+' && cur != '.') break
      }
      s.addChar(cur)
      consumeChar
    }

    // old RecId syntax
    if (s.size == 17 && dashes == 1 && s[8] == '-')
    {
      val = null
      try
      {
        val = Ref.fromRecIdStr(s.toStr)
      }
      catch {} // fall-thru to Number
      if (val != null)
      {
        if (version >= 2) throw Err("Using old RecId syntax in 2.0 zinc grid: $s")
        return tok = scalar
      }
    }

    // Time literal
    if (dashes == 0 && colons > 0)
    {
      if (s[1] == ':') s.insert(0, "0")
      if (colons == 1) s.add(":00")
      val = parseTime(s.toStr)
      return tok = scalar
    }

    // Date literal
    if (dashes == 2 && colons == 0)
    {
      val = parseDate(s.toStr)
      return tok = scalar
    }

    // DateTime
    if (dashes >= 2)
    {
      // xxx timezone
      if (cur != ' ' || !peek.isUpper)
      {
        if (s[-1] == 'Z') s.add(" UTC")
        else throw err("Expecting timezone")
      }
      else
      {
        consumeChar; s.addChar(' ')
        while (cur.isAlpha || cur == '_') { s.addChar(cur); consumeChar }

        // handle GMT+xx or GMT-xx
        if ((cur == '+' || cur == '-') && s[-3] == 'G' && s[-2] == 'M' && s[-1] == 'T')
        {
          s.addChar(cur); consumeChar
          while (cur.isDigit) { s.addChar(cur); consumeChar }
        }
      }
      val = parseDateTime(s.toStr)
      return tok = scalar
    }

    // parse Number value
    Unit? unit := null
    Float float := 0f
    if (unitIndex == 0)
    {
      val = parseNumber(s.toStr, null)
    }
    else
    {
      str := s.toStr
      val = parseNumber(str[0..<unitIndex], str[unitIndex..-1])
    }
    return tok = scalar
  }

  private Int consumeRef()
  {
    // @id part
    if (cur != '@') throw IOErr("Expecting @ for ref literal")
    consumeChar
    s := StrBuf()
    while (true)
    {
      ch := cur
      if (Ref.isIdChar(ch))
      {
        consumeChar
        s.addChar(ch)
      }
      else
      {
        break
      }
    }
    id := s.toStr

    // optional "dis" part
    Str? dis := null
    if (cur == ' ' && peek == '"')
    {
      consumeChar
      consumeStr
      dis = val
    }

    this.val = dis == null ? parseRef(id) : Ref(id, dis)
    return this.tok = scalar
  }

  private Int consumeStr()
  {
    if (cur != '"') throw IOErr("Expecting \" for str literal")
    consumeChar // opening quote
    s := StrBuf()
    while (true)
    {
      ch := cur
      if (ch == '"') { consumeChar; break }
      if (ch == eof) throw err("Unexpected end of str")
      if (ch == '\\') { s.addChar(consumeEscape); continue }
      consumeChar
      s.addChar(ch)
    }
    val = parseStr(s.toStr)
    return tok = scalar
  }

  private Int consumeUri()
  {
    consumeChar // opening backtick
    s := StrBuf()
    while (true)
    {
      ch := cur
      if (ch == '`') { consumeChar; break }
      if (ch == eof || ch == '\n') throw err("Unexpected end of uri")
      if (ch == '\\')
      {
        switch (peek)
        {
          case ':': case '/': case '?': case '#':
          case '[': case ']': case '@': case '\\':
          case '&': case '=': case ';':
            s.addChar(ch)
            s.addChar(peek)
            consumeChar
            consumeChar
          default:
            s.addChar(consumeEscape)
        }
      }
      else
      {
        consumeChar
        s.addChar(ch)
      }
    }
    val = parseUri(s.toStr)
    return tok = scalar
  }

  private Void consumeComment()
  {
    if (peek != '/') throw err("Expecting comment")
    consumeChar; consumeChar
    while (cur != '\n' && cur != eof) consumeChar
  }

//////////////////////////////////////////////////////////////////////////
// Parse/Intern Hooks
//////////////////////////////////////////////////////////////////////////

  @NoDoc virtual Str parseTagName(Str s) { s }
  @NoDoc virtual Number parseNumber(Str float, Str? unit) { Number(Float(float), unit == null ? null : Number.loadUnit(unit)) }
  @NoDoc virtual Ref parseRef(Str s) { Ref(s) }
  @NoDoc virtual Str parseStr(Str s) { s }
  @NoDoc virtual Uri parseUri(Str s) { Uri.fromStr(s) }
  @NoDoc virtual Date parseDate(Str s) { Date.fromStr(s) }
  @NoDoc virtual Time parseTime(Str s) { Time.fromStr(s) }
  @NoDoc virtual DateTime parseDateTime(Str s) { DateTime.fromStr(s) }
  @NoDoc virtual Bin parseBin(Str mime) { Bin(mime) }
  @NoDoc virtual Coord parseCoord(Str s) { Coord.fromStr(s) }

//////////////////////////////////////////////////////////////////////////
// Char Reads
//////////////////////////////////////////////////////////////////////////

  private Int consumeEscape()
  {
    // consume slash
    consumeChar

    // check basics
    switch (cur)
    {
      case 'b':   consumeChar; return '\b'
      case 'f':   consumeChar; return '\f'
      case 'n':   consumeChar; return '\n'
      case 'r':   consumeChar; return '\r'
      case 't':   consumeChar; return '\t'
      case '"':   consumeChar; return '"'
      case '$':   consumeChar; return '$'
      case '\'':  consumeChar; return '\''
      case '`':   consumeChar; return '`'
      case '\\':  consumeChar; return '\\'
    }

    // check for uxxxx
    if (cur == 'u')
    {
      consumeChar
      n3 := cur.fromDigit(16); consumeChar
      n2 := cur.fromDigit(16); consumeChar
      n1 := cur.fromDigit(16); consumeChar
      n0 := cur.fromDigit(16); consumeChar
      if (n3 == null || n2 == null || n1 == null || n0 == null) throw err("Invalid hex value for \\uxxxx")
      return n3.shiftl(12).or(n2.shiftl(8)).or(n1.shiftl(4)).or(n0)
    }

    throw err("Invalid escape sequence")
  }

  private Void consumeChar()
  {
    cur  = peek
    peek = readChar
  }

  private Int readChar()
  {
    ch := in.readChar
    return ch ?: 0
  }

  private Void skipLine()
  {
    while (true)
    {
      ch := in.readChar
      if (ch == '\n' || ch == null) break
    }
    ++line
    this.cur  = readChar
    this.peek = readChar
    consumeToken
  }

  private ParseErr err(Str msg) { ParseErr(msg + " [Line $line]") }

//////////////////////////////////////////////////////////////////////////
// TokenTypes
//////////////////////////////////////////////////////////////////////////

  private Str tokenType(Int ch)
  {
    switch (ch)
    {
      case 'I': return "identifier"
      case 'V': return "scalar"
      case 'N': return "newline"
      default:  return ch.toChar
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private const static Int eof        := 0
  private const static Int identifier := 'I'
  private const static Int scalar     := 'V'
  private const static Int newline    := 'N'

  internal Int tok    // symbol value or token constant such as identifier
  internal Obj? val   // value of literal or identifier
  private InStream in
  private Int version := 0  // 0 unknown, 1 or 2
  internal Int cur
  private Int peek
  @NoDoc Int line := 1 { private set }
}