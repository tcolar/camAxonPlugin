//
// Copyright (c) 2009, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   22 Dec 09  Brian Frank  Creation
//

**
** Dict is a map of name/value pairs which is consistently models Rows,
** grid meta-data, and name/value object literals.  Dict is characterized by:
**   - names must match `Etc.isTagName` rules
**   - values must be one of the built-in scalar types (see `Kind`)
**   - get '[]' access returns null if name not found
**   - trap '->' access throws exception if name not found
**
** Also see `Etc.emptyDict`, `Etc.makeDict`.
**
@Js
const mixin Dict
{
  **
  ** Return if the there are no name/value pairs
  **
  abstract Bool isEmpty()

  **
  ** Get the value for the given name or 'def' is not mapped
  **
  @Operator
  abstract Obj? get(Str name, Obj? def := null)

  **
  ** Return true if the given name is mapped to a non-null value.
  **
  abstract Bool has(Str name)

  **
  ** Return true if the given name is not mapped to a non-null value.
  **
  abstract Bool missing(Str name)

  **
  ** Iterate through the name/value pairs
  **
  abstract Void each(|Obj? val, Str name| f)

  **
  ** Get the value mapped by the given name.  If it is not
  ** mapped to a non-null value, then throw an UnknownNameErr.
  **
  override abstract Obj? trap(Str name, Obj?[]? args := null)

  **
  ** Get the 'id' tag as a Ref or raise CastErr/UnknownNameErr
  **
  Ref id()
  {
    id := get("id", null)
    if (id == null) throw UnknownNameErr("id")
    return id
  }

  **
  ** Deprecated - use `dis`
  **
  @Deprecated Str toDis(Str def := "???") { dis(null, def) }

  **
  ** Get display string for dict or the given tag.  If 'name'
  ** is null, then return display text for the entire dict
  ** using `Etc.dictToDis`.  If 'name' is non-null then format
  ** the tag value using its appropiate 'toLocale' method.  If
  ** 'name' is not defined by this dict, then return 'def'.
  **
  virtual Str? dis(Str? name := null, Str? def := "")
  {
    // if name is null
    if (name == null) return Etc.dictToDis(this, def)

    // get the value, if null return the def
    val := get(name)
    if (val == null) return def

    // fallback to Kind to get a suitable default display value
    return Kind.fromType(val.typeof).valToDis(val)
  }
}

@Js
internal const class EmptyDict : Dict
{
  static const EmptyDict val := EmptyDict()
  override Bool isEmpty() { true }
  override Obj? get(Str key, Obj? def := null) { def }
  override Bool has(Str name) { false }
  override Bool missing(Str name) { true }
  override Void each(|Obj?, Str| f) {}
  override Str toStr() { "{}" }
  override Obj? trap(Str n, Obj?[]? a := null) { throw UnknownNameErr(n) }
}

@NoDoc
@Js
const class MapDict : Dict
{
  new make(Str:Obj? map) { this.map = map.ro }
  const Str:Obj? map
  override Bool isEmpty() { map.isEmpty }
  override Obj? get(Str n, Obj? def := null) { map.get(n, def) }
  override Bool has(Str n) { map[n] != null }
  override Bool missing(Str n) { map[n] == null }
  override Void each(|Obj?, Str| f) { map.each(f) }
  override Str toStr() { ZincWriter.tagsToStr(this) }
  override Obj? trap(Str n, Obj?[]? a := null)
  {
    v := map[n]
    if (v != null) return v
    throw UnknownNameErr(n)
  }
}


