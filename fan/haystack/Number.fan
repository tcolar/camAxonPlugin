//
// Copyright (c) 2010, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   15 Sep 10  Brian Frank  Creation
//

**
** Number represents a numeric value and an optional Unit.
**
@Js
@Serializable { simple = true }
const class Number
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  static const Number negOne := Number(-1f)
  static const Number zero   := Number(0f)
  static const Number one    := Number(1f)
  static const Number ten    := Number(10f)
  static const Number nan    := Number(Float.nan)
  static const Number posInf := Number(Float.posInf)
  static const Number negInf := Number(Float.negInf)

  ** Parse from a string according to zinc syntax
  static new fromStr(Str s, Bool checked := true)
  {
    try
    {
      return ZincReader(s.in).readScalar
    }
    catch (Err e)
    {
      if (checked) throw ParseErr("Number $s.toCode ($e.msg)")
      return null
    }
  }

  ** Construct from scalar value and optional unit.
  new make(Float val, Unit? unit := null)
  {
    this.float   = val
    this.unitRef = unit
  }

  ** Construct from scalar integer and optional unit.
  new makeInt(Int val, Unit? unit := null)
  {
    this.float   = val.toFloat
    this.unitRef = unit
  }

  ** Construct from scalar Int, Float, or Decimal and optional unit.
  static Number makeNum(Num val, Unit? unit := null) { make(val.toFloat, unit) }

  ** Construct from a duration, standardize unit is hours
  ** If unit is null, then a best attempt is made based on magnitude.
  new makeDuration(Duration dur, Unit? unit := hr)
  {
    if (unit == null)
    {
      if (dur < 1sec) unit = ms
      else if (dur < 1min) unit = sec
      else if (dur < 1hr) unit = mins
      else if (dur < 1day) unit = hr
      else unit = day
    }
    this.float   = dur.ticks.toFloat / 1e9f / unit.scale
    this.unitRef = unit
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the scalar value as an Float
  **
  Float toFloat() { float }

  **
  ** Is this number a whole integer without a fractional part
  **
  Bool isInt() { float == float.floor && -1e12f <= float && float <= 1e12f }

  **
  ** Get the scalar value as an Int
  **
  Int toInt() { float.toInt }

  **
  ** Get unit associated with this number or null.
  **
  Unit? unit() { unitRef }

  **
  ** Get this number as a Fantom Duration instance
  **
  Duration? toDuration(Bool checked := true)
  {
    if (unit === hr)   return toDurationMult(1hr)
    if (unit === mins) return toDurationMult(1min)
    if (unit === sec)  return toDurationMult(1sec)
    if (unit === day)  return toDurationMult(1day)
    if (unit === mo)   return toDurationMult(30day)
    if (unit === week) return toDurationMult(7day)
    if (unit === year) return toDurationMult(365day)
    if (unit === ms)   return toDurationMult(1ms)
    if (unit === ns)   return toDurationMult(1ns)
    if (checked) throw UnitErr("Not duration unit: $this")
    return null
  }
  private Duration toDurationMult(Duration mult)
  {
    Duration((float * mult.ticks.toFloat).toInt)
  }

  **
  ** Hash is based on val
  **
  override Int hash() { float.hash }

  **
  ** Equality is based on val and unit.  NaN is equal
  ** to itself (like Float.compare, but unlike Float.equals)
  **
  override Bool equals(Obj? that)
  {
    x := that as Number
    if (x == null) return false
    return float.compare(x.float) == 0 && unit === x.unit
  }

  **
  ** Compare is based on val.
  ** Throw `UnitErr` is this and b have incompatible units.
  **
  override Int compare(Obj that)
  {
    x := (Number)that
    if (unit !== x.unit && unit != null && x.unit != null)
      throw UnitErr("$unit <=> $x.unit")
    return float <=> x.float
  }

  **
  ** Return if this number is approximately equal to that - see `sys::Float.approx`
  **
  Bool approx(Number that, Float? tolerance := null)
  {
    if (unit !== that.unit) return false
    return float.approx(that.float, tolerance)
  }

  **
  ** Is the floating value NaN.
  **
  Bool isNaN() { float.isNaN }

  **
  ** Return if this number if pos/neg infinity or NaN
  **
  Bool isSpecial()
  {
    float == Float.posInf || float == Float.negInf || float.isNaN
  }

  **
  ** String representation
  **
  override Str toStr()
  {
    s := isInt ? toInt.toStr : float.toStr
    if (unit != null && float != Float.posInf && float != Float.negInf && !float.isNaN)
      s += unit.symbol
    return s
  }

  **
  ** Trio/zinc code representation, same as `toStr`
  **
  Str toCode() { toStr }

//////////////////////////////////////////////////////////////////////////
// Operators
//////////////////////////////////////////////////////////////////////////

  **
  ** Negate this number.  Shortcut is -a.
  **
  @Operator Number negate() { make(-float, unit) }

  **
  ** Increment this number.  Shortcut is ++a.
  **
  @Operator Number increment() { make(float+1f, unit) }

  **
  ** Decrement this number.  Shortcut is --a.
  **
  @Operator Number decrement() { make(float-1f, unit) }

  **
  ** Add this with b.  Shortcut is a+b.
  ** Throw `UnitErr` is this and b have incompatible units.
  **
  @Operator Number plus(Number b) { make(float + b.float, plusUnit(unit, b.unit)) }

  private static Unit? plusUnit(Unit? a, Unit? b)
  {
    if (b == null) return a
    if (a == null) return b
    if (a === b)   return a
    if ((a === F && b === Fdeg) || (a === Fdeg && b === F)) return F
    if ((a === C && b === Cdeg) || (a === Cdeg && b === C)) return C
    throw UnitErr("$a + $b")
  }

  **
  ** Subtract b from this.  Shortcut is a-b.
  ** The b.unit must match this.unit.
  **
  @Operator Number minus(Number b) { make(float - b.float, minusUnit(unit, b.unit)) }

  private static Unit? minusUnit(Unit? a, Unit? b)
  {
    if (b == null) return a
    if (a == null) return b
    if (a === F && b === F) return Fdeg
    if (a === C && b === C) return Cdeg
    if (a === F && b === Fdeg) return F
    if (a === C && b === Cdeg) return C
    if (a === b)   return a
    throw UnitErr("$a - $b")
  }

  **
  ** Multiple this and b.  Shortcut is a*b.
  ** The resulting unit is derived from the product of this and b.
  ** Throw `UnitErr` if a*b does not match a unit in the unit database.
  **
  @Operator Number mult(Number b) { make(float * b.float, multUnit(unit, b.unit)) }

  private static Unit? multUnit(Unit? a, Unit? b)
  {
    if (b == null) return a
    if (a == null) return b
    try
      return  a * b
    catch
      return defineUnit(a, '_', b)
  }

  **
  ** Divide this by b.  Shortcut is a/b.
  ** The resulting unit is derived from the quotient of this and b.
  ** Throw `UnitErr` if a/b does not match a unit in the unit database.
  **
  @Operator Number div(Number b) { make(float / b.float, divUnit(unit, b.unit)) }

  private static Unit? divUnit(Unit? a, Unit? b)
  {
    if (b == null) return a
    try
      return a / b
    catch
      return defineUnit(a, '/', b)
  }

  **
  ** Return remainder of this divided by b.  Shortcut is a%b.
  ** The unit of b must be null.
  **
  @Operator Number mod(Number b)
  {
    if (b.unit != null) throw UnitErr("$unit % $b")
    return make(float % b.float, unit)
  }

  private static Unit defineUnit(Unit a, Int symbol, Unit b)
  {
    // build up new string _a/b or _a_b
    s := StrBuf()
    aStr := a.toStr
    if (aStr.startsWith("_")) s.add(aStr)
    else s.addChar('_').add(aStr)

    s.addChar(symbol)

    bStr := b.toStr
    if (bStr.startsWith("_")) bStr = bStr[1..-1]
    s.add(bStr)

    // define if not created yet
    str := s.toStr
    unit := Unit.fromStr(str, false)
    if (unit == null) unit = Unit.define(str)
    return unit
  }

  @NoDoc static Unit? loadUnit(Str str, Bool checked := false)
  {
    unit := Unit.fromStr(str, false)
    if (unit != null) return unit

    if (!str.isEmpty && str[0] == '_') return Unit.define(str)

    if (checked) throw Err("Unit not defined: $str.toCode")
    return null
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Return absolute value of this number.
  **
  Number abs()
  {
    float >= 0f ? this : make(-float, unit)
  }

  **
  ** Return min value
  **
  Number min(Number that)
  {
    float <= that.float ? this : that
  }

  **
  ** Return max value
  **
  Number max(Number that)
  {
    float >= that.float ? this : that
  }

  **
  ** Get the ASCII upper case version of this number as a Unicode point.
  **
  Number upper()
  {
    int := toInt
    up := int.upper
    if (int == up) return this
    return makeInt(up, unit)
  }

  **
  ** Get the ASCII lower case version of this number as a Unicode point.
  **
  Number lower()
  {
    int := toInt
    lo := int.lower
    if (int == lo) return this
    return makeInt(lo, unit)
  }

  **
  ** Format the number according to `sys::Float.toLocale` pattern
  ** language.  Unit symbol is always added as suffix if available.
  **
  Str toLocale(Str? pattern := null)
  {
    if (unit === dollar)
      return StrBuf().addChar('$').add(toFloat.toLocale(pattern ?: "#,##0.00")).toStr

    if (unit === hr)   return toFloat.toLocale("0.##") + "$<sys::hourAbbr>"
    if (unit === mins) return toFloat.toLocale("0.##") + "$<sys::minAbbr>"
    if (unit === sec)  return toFloat.toLocale("0.##") + "$<sys::secAbbr>"

    Str? s
    if (pattern == null)
    {
      fabs := float.abs
      if (isInt) s = toInt.toLocale(null)
      else if (fabs >= 1000f) s = float.toLocale("#,##0")
      else if (fabs < 0.001f) s = toFloat.toStr
      else s = float.toLocale(null)
    }
    else if (pattern == "B")
    {
      s = toInt.toLocale(pattern)
    }
    else
    {
      s = float.toLocale(pattern)
    }

    if (unit != null)
    {
      symbol := unit.symbol
      if (symbol[0] == '_') symbol = symbol[1..-1]
      s += " " + symbol
    }

    return s
  }

//////////////////////////////////////////////////////////////////////////
// Private
//////////////////////////////////////////////////////////////////////////

  @NoDoc const static Unit F       := Unit("fahrenheit")
  @NoDoc const static Unit C       := Unit("celsius")
  @NoDoc const static Unit Fdeg    := Unit("fahrenheit_degrees")
  @NoDoc const static Unit Cdeg    := Unit("celsius_degrees")
  @NoDoc const static Unit ns      := Unit("ns")
  @NoDoc const static Unit ms      := Unit("ms")
  @NoDoc const static Unit sec     := Unit("s")
  @NoDoc const static Unit mins    := Unit("min")
  @NoDoc const static Unit hr      := Unit("h")
  @NoDoc const static Unit day     := Unit("day")
  @NoDoc const static Unit week    := Unit("wk")
  @NoDoc const static Unit mo      := Unit("mo")
  @NoDoc const static Unit year    := Unit("year")
  @NoDoc const static Unit percent := Unit("%")
  @NoDoc const static Unit dollar  := Unit("\$")

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  ** Numeric value
  private const Float float

  ** Optional number
  private const Unit? unitRef

}