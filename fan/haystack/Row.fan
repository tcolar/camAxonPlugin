//
// Copyright (c) 2009, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   22 Dec 09  Brian Frank  Creation
//

**
** Row of a Grid.  Row also implements the Dict mixin to
** expose all of the columns as name/value pairs.
**
@Js
abstract const class Row : Dict
{
  **
  ** Parent  grid
  **
  abstract Grid grid()

  **
  ** Scalar value for the cell
  **
  abstract Obj? val(Col col)

  **
  ** Deprecated in SkySpark 2.0, always returns null
  **
  @Deprecated Str? disVal(Col col) { null }

  **
  ** Deprecated in SkySpark 2.0, always returns empty Dict
  **
  @Deprecated Dict meta(Col col) { Etc.emptyDict }

  **
  ** Get display string for dict or the given tag.  The Row
  ** implementation follows all the same rules as `Dict.dis`
  ** with following enhancements:
  **
  ** If the column meta defines a "format" pattern, then it
  ** is used to format the value via the appropiate 'toLocale'
  ** method.
  **
  override Str? dis(Str? name := null, Str? def := "")
  {
    // if name is null
    if (name == null) return Etc.dictToDis(this, def)

    // find the column, if not found return def
    col := grid.col(name, false)
    if (col == null) return def

    // get the value, if null return the def
    val := this.val(col)
    if (val == null) return def

    // check for explicit formatting meta
    Str? dis := null
    meta := col.meta
    if (!meta.isEmpty)
    {
      // explilcit format toLocale pattern
      format := meta["format"]
      if (format != null)
      {
        m := val.typeof.method("toLocale", false)
        if (m != null && m.params.size != 0)
          dis = m.call(val, format)
      }

      // formatter qname
      formatter := meta["formatter"]
      if (formatter != null)
      {
        try
          dis = ((ColFormatter)Type.find(formatter).make).format(col, this, val)
        catch {}
      }
    }

    // fallback to Kind to get a suitable default display value
    if (dis == null) dis = Kind.fromType(val.typeof).valToDis(val)
    return dis
  }

//////////////////////////////////////////////////////////////////////////
// Dict
//////////////////////////////////////////////////////////////////////////

  **
  ** Always returns false.
  **
  override Bool isEmpty() { false }

  **
  ** Get the column `val` by name.  If column name doesn't
  ** exist or if the column value is null, then return 'def'.
  **
  @Operator
  override Obj? get(Str name, Obj? def := null)
  {
    col := grid.col(name, false)
    if (col == null) return def
    return val(col) ?: def
  }

  **
  ** Get the column `val` by name.  If column name doesn't exist
  ** or if the column value is null, then throw UnknownNameErr.
  **
  override Obj? trap(Str name, Obj?[]? args := null)
  {
    v := val(grid.col(name))
    if (v != null) return v
    throw UnknownNameErr(name)
  }

  **
  ** Return true if the given name is mapped to a non-null column `val`.
  **
  override Bool has(Str name)
  {
    get(name) != null
  }

  **
  ** Return true if the given name is not mapped to a non-null column `val`.
  **
  override Bool missing(Str name)
  {
    get(name) == null
  }

  **
  ** Iterate through all the columns (both null and non-null).
  **
  override Void each(|Obj? val, Str name| f)
  {
    grid.cols.each |col| { f(val(col), col.name) }
  }

  override Str toStr() { ZincWriter.tagsToStr(this) }

}

