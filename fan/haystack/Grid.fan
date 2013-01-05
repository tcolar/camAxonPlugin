//
// Copyright (c) 2009, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   22 Dec 09  Brian Frank  Creation
//

**
** Two dimensional tabular data structure composed of Cols and Rows.
** Grids may be created by factory methods on `Etc`.
** See [docSkyspark]`docSkySpark::Grids`
**
@Js
abstract class Grid
{

//////////////////////////////////////////////////////////////////////////
// Basics
//////////////////////////////////////////////////////////////////////////

  **
  ** Columns
  **
  abstract Col[] cols()

  **
  ** Get a column by its name.  If not resolved then
  ** return null or throw UnknownNameErr based on checked flag.
  **
  abstract Col? col(Str name, Bool checked := true)

  **
  ** Convenience for `cols` mapped to `Col.name`.  The
  ** resulting list is safe for mutating.
  **
  Str[] colNames() { cols.map |col->Str| { col.name } }

  **
  ** Convenience for `cols` mapped to `Col.dis`.  The
  ** resulting list is safe for mutating.
  **
  Str[] colDisNames() { cols.map |col->Str| { col.dis } }

  **
  ** Return if this grid contains the given column name.
  **
  Bool has(Str name) { col(name, false) != null }

  **
  ** Return if this grid does not contains the given column name.
  **
  Bool missing(Str name) { col(name, false) == null }

  **
  ** Iterate the rows
  **
  abstract Void each(|Row row, Int index| f)

  **
  ** Iterate every row until the function returns non-null.  If
  ** function returns non-null, then break the iteration and return
  ** the resulting object.  Return null if the function returns
  ** null for every item
  **
  abstract Obj? eachWhile(|Row row, Int index->Obj?| f)

  **
  ** Return if this is an error grid - meta has "err" tag.
  **
  Bool isErr() { meta.has("err") }

  **
  ** Convenience for `size` equal to zero.
  **
  Bool isEmpty() { size == 0 }

  **
  ** Get the number of rows in the grid.  Throw UnsupportedErr
  ** if the grid doesn't support a size.
  **
  abstract Int size()

  **
  ** Get the first row or return null if grid is empty.
  **
  abstract Row? first()

  **
  ** Get the last row or return null if grid is empty.
  ** Throw UnsupportedErr is the grid doesn't support indexed
  ** based row access.
  **
  virtual Row? last() { isEmpty ? null : get(-1) }

  **
  ** Get a row by its index number.  Throw UnsupportedErr is
  ** the grid doesn't support indexed based row access.
  **
  @Operator
  abstract Row get(Int index)

  **
  ** Meta-data for entire grid
  **
  abstract Dict meta()

//////////////////////////////////////////////////////////////////////////
// Transformations
//////////////////////////////////////////////////////////////////////////

  **
  ** Return true if the function returns true for any of the
  ** rows in the grid.  If the grid is empty, return false.
  **
  Bool any(|Row item, Int index->Bool| f)
  {
    r := eachWhile |item, i|
    {
      f(item, i) ? "hit" : null
    }
    return r != null ? true : false
  }

  **
  ** Return true if the function returns true for all of the
  ** rows in the grid.  If the grid is empty, return false.
  **
  Bool all(|Row item, Int index->Bool| f)
  {
    r := eachWhile |item, i|
    {
      f(item, i) ? null : "miss"
    }
    return r == null ? true : false
  }

  **
  ** Return a new Grid which is a copy of this grid with
  ** the rows sorted by the given comparator function.
  **
  Grid sort(|Row a, Row b->Int| f)
  {
    view := ViewGrid(this)
    view.rows.sort(f)
    return view
  }

  **
  ** Return a new Grid which is a copy of this grid with
  ** the rows reverse sorted by the given comparator function.
  **
  Grid sortr(|Row a, Row b->Int| f)
  {
    view := ViewGrid(this)
    view.rows.sortr(f)
    return view
  }

  **
  ** Convenience for `sort` which sorts the given column by value.
  ** The 'col' parameter can be a `Col` or a str name.
  **
  Grid sortCol(Obj col)
  {
    try { if (size == 0) return this } catch {}
    view := ViewGrid(this)
    c := view.toCol(col)
    view.rows.sort |a, b| { a.val(c) <=> b.val(c) }
    return view
  }

  **
  ** Sort using `Etc.compareDis` and `Dict.dis`.
  **
  Grid sortDis()
  {
    sort |a, b| { Etc.compareDis(a.dis, b.dis) }
  }

  **
  ** Find one matching row or return null if no matches.
  ** Also see `findIndex` and `findAll`.
  **
  Row? find(|Row, Int index->Bool| f)
  {
    eachWhile |row, i| { f(row, i) ? row : null }
  }

  **
  ** Find one matching row index or return null if no matches.
  ** Also see `find`.
  **
  Int? findIndex(|Row, Int index->Bool| f)
  {
    eachWhile |row, i| { f(row, i) ? i : null }
  }

  **
  ** Return a new grid which finds matching the rows in this
  ** grid.  The has the same meta and column definitions.
  ** Also see `find`.
  **
  Grid findAll(|Row, Int index->Bool| f)
  {
    view := ViewGrid(this)
    view.rows = view.rows.findAll(f)
    return view
  }

  **
  ** Return a new grid which is a slice of the rows in
  ** this grid.  Negative indexes may be used to access
  ** from the end of the grid.  The has the same meta
  ** and column definitions.
  **
  @Operator
  Grid getRange(Range r)
  {
    view := ViewGrid(this)
    view.rows = view.rows.getRange(r)
    return view
  }

  **
  ** Return a new grid which maps the rows to new Dict.  The grid
  ** meta and existing column meta are maintained.  New columns
  ** have empty meta.  If the mapping function returns null, then
  ** the row is removed.
  **
  Grid map(|Row, Int index->Dict?| f)
  {
    // perform map
    newRows := Dict[,]
    colNames := Str[,]
    colNamesMap := Str:Str[:]
    each |row, i|
    {
      newRow := f(row, i)
      if (newRow == null) return
      newRows.add(newRow)
      newRow.each |v, n|
      {
        if (colNamesMap[n] == null) { colNames.add(n); colNamesMap[n] = n }
      }
    }

    // build new grid
    ZincCol[] cols := colNames.map |n->ZincCol|
    {
      old := col(n, false)
      return ZincCol(n, old?.meta)
    }
    return ZincGrid(meta, cols).addDictRows(newRows)
  }

  **
  ** Return a new Grid which is the result of applying the given
  ** diffs to this grid.  The diffs must have the same number of
  ** rows as this grid. Any cells in the diffs with a Remove.val
  ** are removed from this grid, otherwise they are updated/added.
  **
  Grid commit(Grid diffs)
  {
    // check sizes
    if (diffs.size != this.size) throw ArgErr("diff.size doesn't match")
    i := 0
    return map |old|
    {
      diff := diffs[i++]
      x := Str:Obj?[:]
      x.ordered = true
      old.each |v, n| { if (v != null) x[n] = v }
      diff.each |v, n| { if (v == Remove.val) x.remove(n); else if (v != null) x[n] = v }
      return Etc.makeDict(x)
    }
  }

  **
  ** Join two grids by column name.  The 'joinCol' parameter may
  ** be a `Col` or col name.  Current implementation requires:
  **  - grids cannot have conflicting col names (other than join col)
  **  - each row in both grids must have a unique value for join col
  **  - grid level meta is merged
  **  - join column meta is merged
  **
  **
  Grid join(Grid that, Obj joinCol)
  {
    // get col references
    a := this;  aJoinCol := a.toCol(joinCol)
    b := that;  bJoinCol := b.toCol(joinCol)

    // get join set of columns
    cols := ZincCol[,]
    a.cols.each |c|
    {
      meta := c.meta
      if (c === aJoinCol)
      {
        meta = Etc.dictMerge(meta, bJoinCol.meta)
      }
      cols.add(ZincCol(c.name, meta))
    }
    b.cols.each |c|
    {
      if (c === bJoinCol) return
      n := c.name
      if (a.has(n)) throw Err("Join column name conflict $n")
       cols.add(ZincCol(c.name, c.meta))
    }

    // map b to hashmap by join col
    bRows := Obj:Row[:] { ordered = true }
    b.each |r| { bRows.add(r.val(bJoinCol), r) }

    // now created merged rows
    newGrid := ZincGrid(Etc.dictMerge(a.meta, b.meta), cols)
    a.each |r|
    {
      cells := Obj?[,]
      a.cols.each |c| { cells.add(r.val(c)) }
      bRow := bRows.remove(r.val(aJoinCol))
      b.cols.each |c|
      {
        if (c === bJoinCol) return
        if (bRow == null) cells.add(null)
        else cells.add(bRow.val(c))
      }
      newGrid.addRow(cells)
    }

    // any rows left over in thatRows are ones missing from this
    bRows.each |r|
    {
      cells := Obj?[,]
      a.cols.each |c|
      {
        if (c === aJoinCol) cells.add(r.val(bJoinCol))
        else cells.add(null)
      }
      b.cols.each |c|
      {
        if (c !== bJoinCol) cells.add(r.val(c))
      }
      newGrid.addRow(cells)
    }

    return newGrid
  }

  **
  ** Return a new grid with additional grid level meta-data.
  ** The meta may be any value accepted by `Etc.makeDict`
  **
  Grid addMeta(Obj? meta)
  {
    view := ViewGrid(this)
    view.meta = Etc.dictMerge(view.meta, meta)
    return view
  }

  **
  ** Return a new grid with an additional column.  The cells of the
  ** column are created by calling the mapping function for each row.
  ** The meta may be any value accepted by `Etc.makeDict`
  **
  Grid addCol(Str name, Obj? meta, |Row, Int->Obj?| f)
  {
    cols := ZincCol[,]
    this.cols.each |c| { cols.add(ZincCol.copy(c)) }
    cols.add(ZincCol(name, meta))
    newGrid := ZincGrid(this.meta, cols)
    each |r, i|
    {
      cells := Obj?[,]
      this.cols.each |c| { cells.add(r.val(c)) }
      cells.add(f(r, i))
      newGrid.addRow(cells)
    }
    return newGrid
  }

  **
  ** Return a new grid with the given column renamed.
  ** The 'oldCol' parameter may be a `Col` or col name.
  **
  Grid renameCol(Obj oldCol, Str newName)
  {
    view := ViewGrid(this)
    view.renameViewCol(oldCol, newName)
    return view
  }

  **
  ** Return a new grid with the columns reordered.  The
  ** given list of names represents the new order and must
  ** contain the same current `Col` instances or column names.
  **
  Grid reorderCols(Obj[] cols)
  {
    view := ViewGrid(this)
    view.reorderViewCols(cols)
    return view
  }

  **
  ** Return a new grid with additional column meta-data.
  ** The 'col' parameter may be either a `Col` or column name.
  ** The meta may be any value accepted by `Etc.makeDict`
  **
  Grid addColMeta(Obj col, Obj? meta)
  {
    view := ViewGrid(this)
    ViewCol c := view.toCol(col)
    c.meta = Etc.dictMerge(c.meta, meta)
    return view
  }

  **
  ** Return a new grid with the given column removed.
  ** The 'col' parameter may be either a `Col` or column name.
  ** If column doesn't exist return this grid.
  **
  Grid removeCol(Obj col)
  {
    if (toCol(col, false) == null) return this
    view := ViewGrid(this)
    view.removeViewCol(col)
    return view
  }

  **
  ** Return a new grid with all the columns removed
  ** except the given columns.  The 'toKeep' columns can
  ** be `Col` instances or column names.
  **
  Grid keepCols(Obj[] toKeep)
  {
    toKeepNames := Str:Col[:]
    toKeep.each |x| { c := toCol(x, false); if (c != null) toKeepNames[c.name] = c }

    toRemove := Col[,]
    cols.each |c|{ if (toKeepNames[c.name] == null) toRemove.add(c) }

    return removeCols(toRemove)
  }

  **
  ** Return a new grid with all the given columns removed.
  ** The 'toRemove' columns can be `Col` instances or column names.
  **
  Grid removeCols(Obj[] toRemove)
  {
    if (toRemove.isEmpty) return this
    view := ViewGrid(this)
    toRemove.each |col| { view.removeViewCol(col) }
    return view
  }

  **
  ** Return a new Grid wich each col name mapped to its localized
  ** tag name if the col does not already have a display string.
  ** See `Etc.tagToLocale` and `docSkySpark::Localization#tags`.
  **
  Grid colsToLocale()
  {
    this as ColsToLocaleViewGrid ?: ColsToLocaleViewGrid(this)
  }

  **
  ** Return a new grid with only rows that define a unique key
  ** by the given key columns.  If multiple rows have the same
  ** key cells, then the first row is returned and subsequent
  ** rows are removed.  The 'keyCols' can be `Col` instances or
  ** column names.
  **
  Grid unique(Obj[] keyCols)
  {
    cols := toCols(keyCols)
    seen := Obj:Str[:]
    return findAll |row|
    {
      key := Obj?[,]
      key.capacity = cols.size
      cols.each |col|
      {
        key.add(row.get(col.name))
      }
      key = key.toImmutable
      if (seen[key] != null) return false
      seen[key] = "seen"
      return true
    }
  }

  **
  ** Internal utility to map Obj[] to Col[]
  **
  internal Col[] toCols(Obj[] cols)
  {
    cols.map |x| { toCol(x) }
  }

  **
  ** Internal utility to map Obj to Col
  **
  internal Col? toCol(Obj c, Bool checked := true)
  {
    if (c is Str) return col(c, checked)
    if (c is Col) return col(((Col)c).name, checked)
    throw ArgErr("Expected Col or Str col name, not '$c.typeof'")
  }

//////////////////////////////////////////////////////////////////////////
// Grouping
//////////////////////////////////////////////////////////////////////////

  **
  ** Group this grid into one or more grouping levels.
  ** The 'cols' parameter can be `Col` instances or column names.
  ** Return a new grid which is re-sorted according to group order
  ** and `groups` indicates the top-level groupings found.
  **
  @NoDoc
  Grid group(Obj[] cols) { isEmpty ? this : GroupGrid(this, cols) }

  **
  ** If this grid has been grouped by `group`, then return
  ** the top-level groups.  If no grouping then return empty list.
  **
  @NoDoc
  virtual Group[] groups() { Group[,] }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Get all the rows as a in-memory list.  We don't expose this
  ** pubically because most code should be using iteration via each.
  **
  internal Row[] toRows()
  {
    rows := Row[,]
    rows.capacity = size
    each |row| { rows.add(row) }
    return rows
  }

  **
  ** Debug dump with some pretty print - no guarantee regarding format.
  ** Options:
  **   - noClip: true to not clip the columns
  **
  @NoDoc Void dump(OutStream out := Env.cur.out, [Str:Obj]? opts := null)
  {
    dumpMeta(out, "Grid:", meta)
    cols.each |col| { dumpMeta(out, "$col.name \"$col.dis\":", col.meta) }

    lines := Str[,].fill("", 2+size)
    cols.each |c| { dumpAddCol(this, c, lines) }

    // optionally clip
    if (opts == null || opts["noClip"] != true)
      lines = lines.map |line| { line.size <= 125 ? line : line[0..125] + "..." }

    if (groups.isEmpty)
    {
      lines.each |line| { out.printLine(line) }
    }
    else
    {
      out.printLine(lines[0])
      out.printLine(lines[1])
      groups.each |group| { dumpGroup(out, group, lines, 0) }
    }
  }

  private Void dumpGroup(OutStream out, Group group, Str[] lines, Int depth)
  {
    switch (depth)
    {
      case 0:  out.print("## ")
      case 1:  out.print("== ")
      default: out.print(":: ")
    }
    out.printLine(group)

    if (group.groups.isEmpty)
    {
      group.each |row, rowIndex| { out.printLine(lines[rowIndex+2]) } // header name/underbars
    }
    else
    {
      group.groups.each |subGroup| { dumpGroup(out, subGroup, lines, depth+1) }
    }
  }

  private static Void dumpMeta(OutStream out, Str title, Dict meta)
  {
    if (meta.isEmpty) return
    out.printLine(title)
    Etc.dictNames(meta).sort.each |n|
    {
      out.printLine(" $n: " + meta[n])
    }
  }

  private static Void dumpAddCol(Grid g, Col c, Str[] lines)
  {
    dips := Str[,]
    g.each |r| { dips.add(toDis(r, c)) }

    width := c.name.size
    dips.each |d| { width = width.max(d.size) }
    sep := lines.first.isEmpty ? "" : "  "

    i := 0
// TODO FIXIT: workaround for array inc bug in compilerJs
    //lines[i++] += sep  + c.name.padr(width)
    //lines[i++] += sep + Str.spaces(width).replace(" ", "-")
    //dips.each |d| { lines[i++] += sep + d.padr(width) }
lines[i] += sep  + c.name.padr(width); i++
lines[i] += sep + Str.spaces(width).replace(" ", "-"); i++
dips.each |d| { lines[i] += sep + d.padr(width); i++ }
  }

  private static Str toDis(Row r, Col c)
  {
    val := r.val(c)
    if (val === Marker.val) return "M"
    if (val === Remove.val) return "R"
    if (val is DateTime && c.meta["format"] == null) return ((DateTime)val).toLocale("DD-MMM-YY hh:mm")
    s := r.dis(c.name)
    b := StrBuf(); s.each |ch| { if (ch > 0x7f) ch = '?'; b.addChar(ch) }
    if (val is Float) return s.split.first // strip units
    return b.toStr
  }
}