//
// Copyright (c) 2009, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   23 Jan 09  Brian Frank  Creation
//   06 Jun 09  Brian Frank  Rewrite Prop into Tag
//   19 Jun 09  Brian Frank  Rename to Kind
//

**
** Kind identifies one of the valid tag value types.
**
@Js
const class Kind
{
  const static Kind ref      := RefKind()
  const static Kind bool     := BoolKind()
  const static Kind number   := NumberKind()
  const static Kind bin      := BinKind()
  const static Kind marker   := MarkerKind()
  const static Kind remove   := RemoveKind()
  const static Kind str      := StrKind()
  const static Kind uri      := UriKind()
  const static Kind dateTime := DateTimeKind()
  const static Kind date     := DateKind()
  const static Kind time     := TimeKind()
  const static Kind coord    := CoordKind()

  static const Kind[] list

  private static const Str:Kind fromStrMap
  static
  {
    map := Str:Kind[:]
    Kind#.fields.each |f|
    {
      if (f.isStatic && f.type == Kind#) map[f.get->name] = f.get
    }
    fromStrMap = map
    list = map.vals.sort
  }

  internal new make(Str name, Type type)
  {
    this.name = name
    this.type = type
    this.fnPrefix = name.lower
  }

  static new fromStr(Str name, Bool checked := true)
  {
    r := fromStrMap[name]
    if (r != null) return r
    if (checked) throw Err("Unknown kind '$name'")
    return null
  }

  static Kind? fromType(Type? type, Bool checked := true)
  {
    if (type === Number#)   return number
    if (type === Marker#)   return marker
    if (type === Str#)      return str
    if (type === Ref#)      return ref
    if (type === DateTime#) return dateTime
    if (type === Bool#)     return bool
    if (type === Coord#)    return coord
    if (type === Uri#)      return uri
    if (type === Bin#)      return bin
    if (type === Date#)     return date
    if (type === Time#)     return time
    if (type === Remove#)   return remove
    if (checked) throw Err("Unknown kind for '$type'")
    return null
  }

  static Kind? fromVal(Obj? val, Bool checked := true)
  {
    fromType(val?.typeof, checked)
  }

  ** Convert value to string
  virtual Str valToStr(Obj val) { val.toStr }

  ** Convert value to zinc string encoding
  virtual Str valToZinc(Obj val) { valToStr(val) }

  ** Convert value to display string
  virtual Str valToDis(Obj val) { val.toStr }

  ** Name of kind: Int, Bool, DateTime
  const Str name

  ** Prefix for method names (lower case name)
  const Str fnPrefix

  ** Type of the kind
  const Type type

  override Bool equals(Obj? that) { this === that }

  override Str toStr() { name }

  ** Default value for this kind
  virtual Obj defVal() { type.make }
}

@Js
internal const class MarkerKind : Kind
{
  new make() : super("Marker", Marker#) {}
  override Str valToZinc(Obj val) { "M" }
  override Str valToDis(Obj val) { "\u2713" }
  override Obj defVal() { Marker.val }
}

@Js
internal const class RemoveKind : Kind
{
  new make() : super("Remove", Remove#) {}
  override Str valToZinc(Obj val) { "R" }
  override Str valToDis(Obj val) { "\u2716" }
}

@Js
internal const class BoolKind : Kind
{
  new make() : super("Bool", Bool#) {}
  override Str valToZinc(Obj val) { val ? "T" : "F" }
}

@Js
internal const class NumberKind : Kind
{
  new make() : super("Number", Number#) {}
  override Str valToDis(Obj val) { ((Number)val).toLocale(null) }
}

@Js
internal const class RefKind : Kind
{
  new make() : super("Ref", Ref#) {}
  override Str valToStr(Obj val) { ((Ref)val).toCode }
  override Str valToDis(Obj val) { ((Ref)val).dis }
  override Str valToZinc(Obj val) { ((Ref)val).toZinc }
}

@Js
internal const class StrKind : Kind
{
  new make() : super("Str", Str#) {}
  override Str valToStr(Obj val) { ((Str)val).toCode }
  override Str valToDis(Obj val)
  {
    s := (Str)val
    if (s.size < 62) return s
    return s[0..60] + "..."
  }
}

@Js
internal const class UriKind : Kind
{
  new make() : super("Uri", Uri#) {}
  override Str valToStr(Obj val) { ((Uri)val).toCode }
}

@Js
internal const class DateTimeKind : Kind
{
  new make() : super("DateTime", DateTime#) {}
  override Str valToStr(Obj val)
  {
    dt := (DateTime)val
    if (dt.tz === TimeZone.utc)
      return dt.toIso
    else
      return dt.toStr
  }
  override Str valToDis(Obj val) { ((DateTime)val).toLocale(null) }
}

@Js
internal const class DateKind : Kind
{
  new make() : super("Date", Date#) {}
  override Str valToDis(Obj val) { ((Date)val).toLocale(null) }
}

@Js
internal const class TimeKind : Kind
{
  new make() : super("Time", Time#) {}
  override Str valToDis(Obj val) { ((Time)val).toLocale(null) }
}

@Js
internal const class BinKind : Kind
{
  new make() : super("Bin", Bin#) {}
}

@Js
internal const class CoordKind : Kind
{
  new make() : super("Coord", Coord#) {}
}

