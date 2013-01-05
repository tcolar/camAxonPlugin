//
// Copyright (c) 2009, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   24 Jun 09  Brian Frank  Create
//

**
** Etc provides folio related utility methods.
**
@Js
const class Etc
{

//////////////////////////////////////////////////////////////////////////
// Dict
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the emtpy Dict instance.
  **
  static Dict emptyDict() { EmptyDict.val }

  **
  ** Empty Str:Obj? map
  **
  @NoDoc static const Str:Obj? emptyTags := [:]

  **
  ** Make a Dict instance where 'val' is one of the following:
  **   - Dict: return 'val'
  **   - null: return `emptyDict`
  **   - Str[]: dictionary of key/Marker value pairs
  **   - Str:Obj?: wrap map as Dict
  **
  static Dict makeDict(Obj? val)
  {
    if (val == null) return emptyDict
    if (val is Dict) return val
    if (val is List)
    {
      tags := Str:Obj[:]
      ((List)val).each |Str key| { tags[key] = Marker.val }
      return factory.fromMap(tags)
    }
    Str:Obj? map := val
    return map.isEmpty ? emptyDict : factory.fromMap(map)
  }

  private static const EtcDictFactory factory
  static
  {
    try
      factory = Type.find("dict::DictFactory").make
    catch
      factory = EtcDictFactory()
  }

  **
  ** Make a list of Dict instances using `makeDict`.
  **
  static Dict[] makeDicts(Obj?[] maps)
  {
    maps.map |map -> Dict| { makeDict(map) }
  }

  **
  ** Get a read/write list of the dict's name keys.
  **
  static Str[] dictNames(Dict d)
  {
    names := Str[,]
    d.each |v, n| { names.add(n) }
    return names
  }

  **
  ** Given a list of dictionaries, find all the common names
  ** used.  Return the names in standard sorted order.
  **
  static Str[] dictsNames(Dict[] dicts)
  {
    Str:Str map := Str:Str[:] { ordered = true }
    hasId := false
    hasMod := false
    dicts.each |dict|
    {
      dict.each |v, n|
      {
        if (n == "id")  { hasId  = true; return }
        if (n == "mod") { hasMod = true; return }
        map[n] = n
      }
    }
    list := map.vals.sort
    if (hasId)  list.insert(0, "id")
    if (hasMod) list.add("mod")
    return list
  }

  **
  ** Get all the non-null values mapped by a dictionary.
  **
  static Obj?[] dictVals(Dict d)
  {
    vals := Obj?[,]
    d.each |v, n| { vals.add(v) }
    return vals
  }

  **
  ** Convert a Dict to a read/write map.  This method is expensive,
  ** when possible you should instead use `Dict.each`.
  **
  static Str:Obj? dictToMap(Dict d)
  {
    map := Str:Obj?[:]
    d.each |v, n| { map[n] = v }
    return map
  }

  **
  ** Return if the given value is one of the scalar
  ** values supported by dictions and grids.
  **
  static Bool isDictVal(Obj? val)
  {
    val == null || Kind.fromType(val.typeof, false) != null
  }

  **
  ** Apply the given map function to each name/value pair
  ** to construct a new Dict.
  **
  static Dict dictMap(Dict d, |Obj? v, Str n->Obj?| f)
  {
    map := Str:Obj?[:]
    d.each |v, n| { map[n] = f(v, n) }
    return makeDict(map)
  }

  **
  ** Apply the given map function to each name/value pair
  ** to construct a new Dict.
  **
  static Dict dictFindAll(Dict d, |Obj? v, Str n->Obj?| f)
  {
    map := Str:Obj?[:]
    d.each |v, n| { if (f(v, n)) map[n] = v }
    return makeDict(map)
  }


  **
  ** Add/set all the name/value pairs in a with those defined
  ** in b.  If b defines a remove value then that name/value is
  ** removed from a.  The b parameter may be any value
  ** accepted by `makeDict`
  **
  static Dict dictMerge(Dict a, Obj? b)
  {
    if (b == null) return a
    tags := dictToMap(a)
    if (b is Dict)
    {
      bd := (Dict)b
      if (bd.isEmpty) return a
      bd.each |v, n|
      {
        if (v === Remove.val) tags.remove(n)
        else tags[n] = v
      }
    }
    else
    {
      bm := (Str:Obj?)b
      if (bm.isEmpty) return a
      bm.each |v, n|
      {
        if (v === Remove.val) tags.remove(n)
        else tags[n] = v
      }
    }
    return makeDict(tags)
  }

  **
  ** Set a name/val pair in an existing dict.
  **
  static Dict dictSet(Dict d, Str name, Obj? val)
  {
    map := Str:Obj?[:]
    if (d is Row) map.ordered = true
    d.each |v, n| { map[n] = v }
    map[name] = val
    return MapDict(map)
  }

  **
  ** Set a name/val pair in an existing dict.
  **
  static Dict dictRemove(Dict d, Str name)
  {
    if (d.missing(name)) return d
    map := Str:Obj?[:]
    d.each |v, n| { map[n] = v }
    map.remove(name)
    return map.isEmpty ? emptyDict : MapDict(map)
  }

//////////////////////////////////////////////////////////////////////////
// Dis
//////////////////////////////////////////////////////////////////////////

  **
  ** Given a dic, attempt to find the best display string:
  **   1. 'disMacro' tag returns `macro` using dict as scope
  **   2. 'dis' tag
  **   3. 'name' tag
  **   4. 'tag' tag
  **   5. 'id' tag
  **   6. default
  **
  static Str? dictToDis(Dict dict, Str? def := "")
  {
    disMacro := dict.get("disMacro", null) as Str
    if (disMacro != null) return macro(disMacro, dict)

    Obj? d
    d = dict.get("dis", null);  if (d != null) return d.toStr
    d = dict.get("name", null); if (d != null) return d.toStr
    d = dict.get("tag", null);  if (d != null) return d.toStr
    id := dict.get("id", null) as Ref; if (id != null) return id.dis
    return def
  }

  **
  ** Get a relative display name.  If the child display name
  ** starts with the parent, then we can strip that as the
  ** common suffix.
  **
  static Str relDis(Str parent, Str child)
  {
    // we could really improve efficiency of this
    p := parent.split
    c := child.split
    m := p.size.min(c.size)
    i := 0
    while (i < m && p[i] == c[i]) ++i
    if (i == 0 || i >= c.size) return child
    return c[i..-1].join(" ")
  }

  **
  ** Given two display strings, return 1, 0, or -1 if a is less
  ** than, equal to, or greater than b.  The comparison is case
  ** insensitive and takes into account trailing digits so that a
  ** dis str such as "Foo-10" is greater than "Foo-2".
  **
  static Int compareDis(Str a, Str b)
  {
    // handle empty strings
    if (a.isEmpty) return b.isEmpty ? 0 : -1
    if (b.isEmpty) return 1

    // check first chars as quick optimization
    a0 := a[0].lower
    b0 := b[0].lower
    if (a0 != b0) return a0 <=> b0

    // check if we don't have trailing digits,
    // then use normal locale compare
    if (!a[-1].isDigit || !b[-1].isDigit) return a.localeCompare(b)

    // find first index of digits
    adi := a.size; while(adi>0 && a[adi-1].isDigit) --adi
    bdi := b.size; while(bdi>0 && b[bdi-1].isDigit) --bdi

    // check if prefixes are equal
    if (adi != bdi) return a.localeCompare(b)
    for (i:=0; i<adi; ++i)
      if (a[i].lower != b[i].lower) return a[i] <=> b[i]

    // prefixes are equal, compare by digits
    return a[adi..-1].toInt <=> b[bdi..-1].toInt
  }

  **
  ** Process macro pattern with given scope of variable name/value pairs.
  ** The pattern is a Unicode string with embedded expressions:
  **  - '$tag': resolve tag name from scope
  **  - '${tag}': resolve tag name from scope
  **  - '$<pod::key>': localization key
  **
  ** If a tag resolves to Ref, then we use Ref.dis for string.
  **
  static Str macro(Str pattern, Dict scope)
  {
    try
      return Macro(pattern, scope).apply
    catch (Err e)
      return pattern
  }

//////////////////////////////////////////////////////////////////////////
// Names
//////////////////////////////////////////////////////////////////////////

  **
  ** Return if the given string is a legal tag name:
  **   - first char must be ASCII lower case
  **     letter: 'a' - 'z'
  **   - rest of chars must be ASCII letter or
  **     digit: 'a' - 'z', 'A' - 'Z', '0' - '9', or '_'
  **
  static Bool isTagName(Str n)
  {
    if (n.isEmpty || !n[0].isLower) return false
    return n.all |c| { c.isAlphaNum || c == '_' }
  }

   **
   ** Take an arbitrary string ane convert into a safe tag name.
   **
   static Str toTagName(Str n)
   {
     if (n.isEmpty) throw ArgErr("string is empty")
     n = n.fromDisplayName
     buf := StrBuf()
     n.each |ch|
     {
       if (ch.isAlphaNum)
       {
         if (buf.isEmpty)
         {
           if (ch.isDigit) buf.addChar('v').addChar(ch)
           else if (ch.isUpper) buf.addChar(ch.lower)
           else buf.addChar(ch)
         }
         else buf.addChar(ch)
       }
     }
     if (buf.isEmpty) return "v"
     return buf.toStr
   }

  **
  ** Get the localized string for the given tag name for the
  ** current locale. See `docSkySpark::Localization#tags`.
  **
  static Str tagToLocale(Str name)
  {
    pod := Pod.find("proj")
    locale := Locale.cur
    props := Env.cur.props(pod, `tags/${locale.lang}.props`, Duration.maxVal)
    return props[name] ?: name
  }

//////////////////////////////////////////////////////////////////////////
// Grids
//////////////////////////////////////////////////////////////////////////

  **
  ** Given an arbitrary object, translate it to a Grid suitable
  ** for serizliation with Zinc:
  **   - if grid just return it
  **   - if row in grid of size, return row.grid
  **   - if scalar return 1x1 grid
  **   - if dict return grid where dict is only
  **   - if list of dict return grid where each dict is row
  **   - if list of non-dicts, return one col grid with rows for each item
  **   - if non-zinc type return grid with cols val, type
  **
  static Grid toGrid(Obj? val)
  {
    // if already a Grid
    if (val is Grid) return (Grid)val

    // if a Row in a single row Grid
    if (val is Row)
    {
      grid := ((Row)val).grid
      try
        if (grid.size == 1) return grid
      catch {}
    }

    // if value is a Dict map to a 1 row grid
    if (val is Dict) return makeDictGrid(null, val)

    // if value is a list
    if (val is List)
    {
      // if list is all dicts, turn into real NxN grid
      list := (List)val
      if (list.all { it is Dict }) return makeDictsGrid(null, val)

      // otherwise just turn it into a 1 column grid
      grid := ZincGrid(emptyDict, [ZincCol("val")])
      list.each |v| { grid.addRow([toCell(v)]) }
      return grid
    }

    // scalar translate to 1x1 Grid
    grid := ZincGrid(emptyDict, [ZincCol("val")])
    grid.addRow([toCell(val)])
    return grid
  }

  private static Obj? toCell(Obj? val)
  {
    if (isDictVal(val)) return val
    return "$val.toStr [$val.typeof]"
  }

  **
  ** Construct an empty grid with just the given grid level meta-data.
  ** The meta parameter can be any `makeDict` value.
  **
  static Grid makeEmptyGrid(Obj? meta := null)
  {
    ZincGrid(makeDict(meta), [ZincCol("empty")])
  }

  **
  ** Construct a grid for an error response.
  **
  static Grid makeErrGrid(Err e, Obj? meta := null)
  {
    // figure out trace
    trace := e.traceToStr
    if (e.typeof.field("axonTrace", false) != null)
    {
      trace = "ERROR: $e.msg\n\n" + e->axonTrace + "\n" + trace
    }

    // core tags
    tags := [
      "err":Marker.val,
      "dis": e.toStr,
      "errTrace": trace,
      "errType":e.typeof.qname
    ]

    // additional tags
    if (meta != null) makeDict(meta).each |v, n| { tags[n] = v }

    return makeEmptyGrid(tags)
  }

  **
  ** Convenience for `makeDictGrid`
  **
  static Grid makeMapGrid(Obj? meta, Str:Obj? row)
  {
    makeDictGrid(meta, makeDict(row))
  }

  **
  ** Convenience for `makeDictsGrid`
  **
  static Grid makeMapsGrid(Obj? meta, [Str:Obj?][] rows)
  {
    makeDictsGrid(meta, makeDicts(rows))
  }

  **
  ** Construct a grid for a Dict row.
  ** The meta parameter can be any `makeDict` value.
  **
  static Grid makeDictGrid(Obj? meta, Dict row)
  {
    cols  := ZincCol[,]
    cells := Obj?[,]
    if (row.has("id")) { cols.add(ZincCol("id")); cells.add(row["id"]) }
    row.each |v, n|
    {
      if (n == "id" || n == "mod") return
      cols.add(ZincCol(n))
      cells.add(v)
    }
    if (row.has("mod")) { cols.add(ZincCol("mod")); cells.add(row["mod"]) }
    if (cols.isEmpty) return makeEmptyGrid(meta)
    grid := ZincGrid(makeDict(meta), cols)
    grid.addRow(cells)
    return grid
  }

  **
  ** Construct a grid for a list of Dict rows.
  ** The meta parameter can be any `makeDict` value.
  **
  static Grid makeDictsGrid(Obj? meta, Dict[] rows)
  {
    // boundary cases
    if (rows.isEmpty) return makeEmptyGrid(meta)
    if (rows.size == 1) return makeDictGrid(meta, rows.first)

    // just brute force it for now

    // first pass finds all the unique columns
    colNames := dictsNames(rows)
    if (colNames.isEmpty) throw ArgErr("cols are empty")
    ZincCol[] cols := colNames.map |n,i->ZincCol| { ZincCol(n) }

    // map rows
    return ZincGrid(makeDict(meta), cols).addDictRows(rows)
  }

  **
  ** Construct a grid with one column for a list.  The meta
  ** and colMeta parameters can be any `makeDict` value.
  **
  static Grid makeListGrid(Obj? meta, Str colName, Obj? colMeta, Obj?[] rows)
  {
    grid := ZincGrid(makeDict(meta), [ZincCol(colName, colMeta)])
    rows.each |v| { grid.addRow([v]) }
    return grid
  }

  **
  ** Construct a grid for a list of rows, where each row is
  ** a list of cells.  The meta and colMetas parameters can
  ** be any `makeDict` value.
  **
  static Grid makeListsGrid(Obj? meta, Str[] colNames, Obj?[]? colMetas, Obj?[][] rows)
  {
    cols := colNames.map |n, i->ZincCol| { ZincCol(n, colMetas?.get(i)) }
    grid := ZincGrid(makeDict(meta), cols)
    rows.each |row| { grid.addRow(row) }
    return grid
  }

  **
  ** Given an existing grid, return a new grid which uses a callback
  ** to provide the display string for cells and columns. If the cb
  ** returns null, then normal display formatting is applied.
  ** If the callback is invoked with a null row then return display
  ** value for column, otherwise return display value for cell.
  **
  ** TODO: this functionality has been deprecated with 2.0 with removal
  **   of cell dis/meta.  Use of this grid will no longer encode to
  **   Zinc correctly
  **
  @Deprecated
  @NoDoc
  static Grid makeDisValGrid(Grid grid, |Col,Row?->Str?| cb)
  {
    grid
  }

}

**************************************************************************
** DictFactory
**************************************************************************

@Js
@NoDoc
const class EtcDictFactory
{
  virtual Dict fromMap(Str:Obj? map) { MapDict(map) }
}