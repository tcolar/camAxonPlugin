//
// Copyright (c) 2010, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   03 Jan 10  Brian Frank  Creation
//

**
** Wrap a grid with an alternate view.
**
@Js
internal class ViewGrid : Grid
{
  new make(Grid src)
  {
    this.src = src
    this.meta = src.meta
    this.cols = src.cols.map |c->ViewCol| { ViewCol(this, c) }
    this.colsByName = Str:ViewCol[:].addList(cols) { it.name }
    this.rows = ViewRow[,] { capacity = src.size }
    src.each |r| { rows.add(ViewRow(ref, r)) }
  }

  Grid src
  const Unsafe ref := Unsafe(this)
  override Dict meta

  Str:ViewCol colsByName
  override ViewCol[] cols
  override Col? col(Str name, Bool checked := true)
  {
    col := colsByName[name]
    if (col != null || !checked) return col
    throw UnknownNameErr(name)
  }

  Void renameViewCol(Obj old, Str newName)
  {
    ViewCol c := toCol(old)
    colsByName.remove(c.name)
    c.name = newName
    colsByName.add(newName, c)
  }

  Void removeViewCol(Obj col)
  {
    c := toCol(col, false)
    if (c == null) return
    colsByName.remove(c.name)
    cols.removeSame(c)
  }

  Void reorderViewCols(Obj[] cs)
  {
    if (cs.size != cols.size) throw ArgErr("Mismatch num cols $cols.size != $cs.size")
    newCols := ViewCol[,]
    dups    := Str:Str[:]
    cs.each |c|
    {
      col := toCol(c)
      if (dups[col.name] != null) throw ArgErr("Duplicate col name $col.name")
      dups[col.name] = col.name
      newCols.add(col)
    }
    this.cols = newCols
  }

  ViewRow[] rows
  override Void each(|Row,Int| f) { rows.each(f) }
  override Obj? eachWhile(|Row,Int->Obj?| f) { rows.eachWhile(f) }
  override Int size() { rows.size }
  override Row get(Int index) { rows[index] }
  override Row? first() { rows.first }
}

**************************************************************************
** ColsToLocaleViewGrid
**************************************************************************

@Js
internal class ColsToLocaleViewGrid : ViewGrid
{
  new make(Grid src) : super(src)
  {
    cols.each |col|
    {
      if (col.meta.missing("dis"))
      {
        col.meta = Etc.dictSet(col.meta, "dis", Etc.tagToLocale(col.name))
      }
    }
  }
}

**************************************************************************
** ViewCol
**************************************************************************

@Js
internal class ViewCol : Col
{
  new make(ViewGrid grid, Col src)
  {
    this.grid = grid
    this.src  = src
    this.name = src.name
    this.meta = src.meta
  }
  ViewGrid grid
  Col src
  override Str name
  override Dict meta
}

**************************************************************************
** ViewRow
**************************************************************************

@Js
internal const class ViewRow : Row
{
  new make(Unsafe g, Row src) { this.gridRef = g; this.src = src }
  override ViewGrid grid() { gridRef.val }
  override Obj? val(Col col) { src.val(((ViewCol)col).src) }
  override Str toStr() { src.toStr }
  const Unsafe gridRef
  const Row src
}