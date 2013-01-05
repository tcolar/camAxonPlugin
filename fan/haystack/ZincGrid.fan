//
// Copyright (c) 2009, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   28 Dec 09  Brian Frank  Creation
//

**************************************************************************
** ZincGrid
**************************************************************************

@Js
@NoDoc
class ZincGrid : Grid
{
  new make(Obj? meta, ZincCol[] cols)
  {
    this.meta = Etc.makeDict(meta)
    this.cols = cols.ro
    this.cols.each |col, i| { col.index = i }
    this.colsByName = Str:ZincCol[:].addList(cols) { it.name }
  }

  const Unsafe ref := Unsafe(this)

  override ZincCol[] cols

  override Col? col(Str name, Bool checked := true)
  {
    col := colsByName[name]
    if (col != null || !checked) return col
    throw UnknownNameErr(name)
  }

  override Void each(|Row,Int| f) { rows.each(f) }
  override Obj? eachWhile(|Row,Int->Obj?| f) { rows.eachWhile(f) }
  override Int size() { rows.size }
  override Row get(Int index) { rows[index] }
  override Row? first() { rows.first }

  override Dict meta

  Void addRow(Obj?[] cells)
  {
    rows.add(ZincRow(ref, cells))
  }

  This addDictRows(Dict[] dicts)
  {
    dicts.each |dict| { addDictRow(dict) }
    return this
  }

  This addDictRow(Dict dict)
  {
    cells := Obj?[,]
    cells.size = cols.size
    dict.each |v, n|
    {
      // map value into cells by index
      cells[colsByName[n].index] = v
    }
    rows.add(ZincRow(ref, cells))
    return this
  }

  Str:ZincCol colsByName
  ZincRow[] rows := ZincRow[,]
}

**************************************************************************
** ZincCol
**************************************************************************

@Js
@NoDoc
class ZincCol : Col
{
  static ZincCol[] copyAll(Col[] cols)
  {
    cols.map |col->ZincCol| { copy(col) }
  }

  static Obj? copy(Col c)
  {
    make(c.name, c.meta)
  }

  new make(Str name, Obj? meta := null)
  {
    this.name = name
    this.meta = Etc.makeDict(meta)
  }

  internal Int index

  override const Str name
  override const Dict meta
}

**************************************************************************
** ZincRow
**************************************************************************

@Js
@NoDoc
const class ZincRow : Row
{
  new make(Unsafe g, Obj?[] cells) { this.gridRef = g; this.cells = cells }

  override ZincGrid grid() { gridRef.val }

  const Unsafe gridRef
  const Obj?[] cells  // scalar values or ZincCells

  override Obj? val(Col col)
  {
    cells[((ZincCol)col).index]
  }
}