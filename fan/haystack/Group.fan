//
// Copyright (c) 2009, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   03 Jan 10  Brian Frank  Creation
//

**
** Grouping of a grid rows.
**
@NoDoc
@Js
class Group
{
  **
  ** Internal constructor used by GroupGrid
  **
  internal new make(GroupGrid grid, Col col, Row proto, Range range)
  {
    this.groupGrid   = grid
    this.groupCol    = col
    this.groupVal    = proto.val(col)
    this.groupValDis = proto.dis(col.name)
    this.range       = range
  }

  **
  ** Grid associated with this grouping
  **
  Grid grid() { groupGrid }

  **
  ** Grid column used to organize this grouping
  **
  Col col() { groupCol }

  **
  ** Value of `col` which defined this grouping
  **
  Obj? val() { groupVal }

  **
  ** Display string for `val`
  **
  Str valDis() { groupValDis }

  **
  ** Return sub-groups or empty list.
  **
  Group[] groups() { subGroups.ro }

  **
  ** Get the number of rows in this group.
  **
  Int size() { range.max - range.min + 1 }

  **
  ** Iterate the rows in this group.
  **
  Void each(|Row row, Int index| f)
  {
    groupGrid.rows.eachRange(range, f)
  }

  **
  ** Given a `Col` or column name, return the rollup of that
  ** column within this grouping.  Rows without a Number value
  ** for the given column are skipped.  Return null if no matching
  ** Number rows.
  **
  @NoDoc Number? rollup(Obj col)
  {
    c := groupGrid.toCol(col, false)
    if (c == null) return null
    Number? acc := null
    each |row|
    {
      val := row.val(c) as Number
      if (val == null) return
      acc = (acc == null) ? val : acc + val
    }
    return acc
  }

  override Str toStr() { "${groupCol.name}: $valDis" }

  /*
  internal Void dump(Int indent := 0)
  {
    echo("${Str.spaces(indent)}$groupValDis $range")
    subGroups.each |sub| { sub.dump(indent+2) }
  }
  */

  private GroupGrid groupGrid
  private Col groupCol
  private Obj? groupVal
  private Str groupValDis
  internal Range range
  internal Group[] subGroups := Group[,]
}

**************************************************************************
** GroupGrid
**************************************************************************

@Js
internal class GroupGrid : ViewGrid
{
  new make(Grid src, Obj[] groupColObjs) : super(src)
  {
    // sort rows by grouping
    Col[] groupCols := groupColObjs.map |c->Col| { toCol(c) }
    rows.sort |a, b| { compareByGroups(groupCols, a, b) }

    // now build up our top-level groups
    this.groups = findGroups(0..<rows.size, groupCols.first).ro

    // compute sub-groups recursively
    findSubGroups(groups, groupCols, 1)
  }

  Void findSubGroups(Group[] groups, Col[] groupCols, Int depth)
  {
    // if now more levels we are done
    if (depth >= groupCols.size) return

    // iterate each group finding its sub-groups recursively
    groups.each |group|
    {
      group.subGroups = findGroups(group.range, groupCols[depth])
      findSubGroups(group.subGroups, groupCols, depth+1)
    }
  }

  Group[] findGroups(Range range, Col col)
  {
    acc := Group[,]
    startIndex := -1
    rows.eachRange(range) |row, rowIndex|
    {
      if (startIndex >= 0 && rows[startIndex].val(col) == row.val(col)) return
      if (!acc.isEmpty) acc.last.range = startIndex .. rowIndex-1
      acc.add(Group(this, col, row, rowIndex..range.last))
      startIndex = rowIndex
    }
    return acc
  }

  override Group[] groups := [,] { private set }

  static Int compareByGroups(Col[] cols, Row a, Row b)
  {
    i := 0
    while (i < cols.size)
    {
      col := cols[i++]
      cmp := a.val(col) <=> b.val(col)
      if (cmp != 0) return cmp
    }
    return Etc.compareDis(a.dis, b.dis)
  }

}

