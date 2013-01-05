//
// Copyright (c) 2009, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   3 Jan 09  Brian Frank  Creation
//

**
** RecId is deprecated, use `Ref`
**
@Deprecated
@Js const mixin RecId
{
  new static fromStr(Str s, Bool checked := true) { Ref.fromRecIdStr(s, checked) }

  new static gen() { Ref.gen() }

  new static nullId() { Ref.nullRef }

  new static defVal() { Ref.defVal }

  abstract Bool isNull()
}

/* REF-TODO
//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Parse a record id from the following
  ** string format: "tttttttt-rrrrrrrr"
  **
  static new fromStr(Str s, Bool checked := true)
  {
    try
    {
      // 01234567890123456
      // tttttttt-rrrrrrrr
      if (s.size == 17 && s[8] == '-')
      {
        time   := s[0..7].toInt(16)
        rand   := s[9..16].toInt(16)
        handle := time.and(0xffff_ffff).shiftl(32).or(rand.and(0xffff_ffff))
        return make(handle)
      }
    }
    catch {}
    if (checked) throw ParseErr("Invalid RecId: $s")
    return null
  }

  **
  ** Generate a unique RecId.
  **
  static RecId gen()
  {
    rand   := Int.random
    time   := DateTime.nowTicks / 1sec.ticks
    handle := time.and(0xffff_ffff).shiftl(32).or(rand.and(0xffff_ffff))
    return make(handle)
  }

  **
  ** Make an id from its 64-bit UUID handle.
  ** The top most bit must always be zero.
  **
  new make(Int handle)
  {
    // ensure top byte starts isn't 'a' - 'f'
    if (handle.shiftr(56).and(0xff) >= 0xa0)
      throw ArgErr("Invalid RecId handle top byte: $handle.toHex")
    this.handle = handle
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** Get the 64-bit integer handle component of this identifier.
  **
  const Int handle

  **
  ** Get the time component of the handle which is top 32-bits.
  ** The time is the number of seconds since 1 Jan 2000.
  **
  Int time() { handle.shiftr(32).and(0xffff_ffff) }

  **
  ** Get the random component of the handle which is bottom 32 bits.
  ** This value is a randomly generated number can be used to evenly
  ** distribute records for sharding.
  **
  Int rand() { handle.and(0xffff_ffff) }

  **
  ** Hash handle.
  **
  override Int hash() { handle }

  **
  ** Equality is based on handle.
  **
  override Bool equals(Obj? that)
  {
    x := that as RecId
    if (x == null) return false
    return handle == x.handle
  }

  **
  ** String format is: "tttttttt-rrrrrrrr"
  **
  override Str toStr()
  {
    StrBuf(20).add(time.toHex(8)).addChar('-').add(rand.toHex(8)).toStr
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** Is this the null id?
  **
  Bool isNull() { handle == 0 }

  **
  ** Get the id as an abbreviated string.
  **
  Str toAbbr()
  {
    if (isNull) return "null"
    return rand.toHex(8)
  }

  **
  ** For the purposes of the query language we use the str format.
  **
  Str toCode() { toStr }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  const static RecId nullId := RecId.make( 0)

  const static RecId defVal := nullId
*/