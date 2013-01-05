//
// Copyright (c) 2009, SkyFoundry LLC
// All Rights Reserved
//
// History:
//    3 Jan 09  Brian Frank  Creation
//   17 Sep 12  Brian Frank  Rework RecId -> Ref
//

**
** Ref is used to model a record identifier and optional display string.
**
@Js
@Serializable { simple = true }
const class Ref : RecId
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  ** Make with simple id
  static new fromStr(Str id) { makeImpl(id, null) }

  ** Construct with id string and optional display string.
  static new make(Str id, Str? dis)
  {
    makeImpl(id, dis)
  }

  ** Construct with Ref id string and optional display string.
  static new makeWithDis(Ref ref, Str? dis := null)
  {
    if (dis == null && ref.disVal == null) return ref
    return makeImpl(ref.id, dis)
  }

  ** Generate a unique Ref.
  static Ref gen()
  {
    // format as: "tttttttt-rrrrrrrr"
    time := (DateTime.nowTicks / 1sec.ticks).and(0xffff_ffff)
    rand := (Int.random).and(0xffff_ffff)
    handle := time.and(0xffff_ffff).shiftl(32).or(rand.and(0xffff_ffff))
    return makeHandle(handle)
  }

  ** Construct with 64-bit handle
  @NoDoc static new makeHandle(Int handle)
  {
    // ensure top byte starts isn't 'a' - 'f'
    if (handle.shiftr(56).and(0xff) >= 0xa0)
      throw ArgErr("Invalid RecId handle top byte: $handle.toHex")

    time := handle.shiftr(32).and(0xffff_ffff)
    rand := handle.and(0xffff_ffff)
    id := StrBuf(20).add(time.toHex(8)).addChar('-').add(rand.toHex(8)).toStr
    return makeImpl(id, null)
  }

  ** Constructor
  @NoDoc private new makeImpl(Str id, Str? dis)
  {
    this.idRef = id
    this.disValRef = dis
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  ** Identifier which does **not** include the leading '@'
  Str id() { idRef }
  private const Str idRef

  ** Optional display string for what the identifier references or null.
  Str? disVal() { disValRef }
  private const Str? disValRef

  ** Get this ref as 64-bit handle or throw UnsupportedErr
  @NoDoc Int handle()
  {
    try
    {
      if (id.size == 17 && id[8] == '-')
      {
        time := id[0..7].toInt(16)
        rand := id[9..16].toInt(16)
        return time.and(0xffff_ffff).shiftl(32).or(rand.and(0xffff_ffff))
      }
    }
    catch (Err e) {}
    if (isNull) return 0
    throw UnsupportedErr("Not handle Ref: $id")
  }

  ** Hash `id`
  override Int hash() { id.hash }

  ** Equality is based on `id` only (not dis).
  override Bool equals(Obj? that)
  {
    x := that as Ref
    if (x == null) return false
    return id == x.id
  }

  ** Return `disVal` or if not available, then return `id`
  Str dis() { disValRef ?: idRef }

  ** String format is `id` which does **not** include
  ** the leading '@'.  Use `toCode` to include leading '@'.
  override Str toStr() { id }

  ** Return "@id"
  Str toCode() { StrBuf(id.size+1).addChar('@').add(id).toStr }

  ** Parse "@id"
  @NoDoc static Ref fromCode(Str s)
  {
    if (!s.startsWith("@")) throw ParseErr("Missing leading @: $s")
    return fromStr(s[1..-1])
  }

  ** Return "[@id, @id, ...]"
  @NoDoc static Str toCodeList(Ref[] refs)
  {
    s := StrBuf(refs.size*20).addChar('[')
    refs.each |ref, i|
    {
      if (i > 0) s.addChar(',')
      s.addChar('@').add(ref.id)
    }
    return s.addChar(']').toStr
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  ** Null ref has id value of "null"?
  override Bool isNull() { id == "null" || id == "00000000-00000000" }

  **
  ** Is the given character a valid id char:
  **  - 'A' - 'Z'
  **  - 'a' - 'z'
  **  - '0' - '9'
  **  - '_ : - . ~'
  **
  static Bool isIdChar(Int char)
  {
    if (char < 127) return idChars[char]
    return false
  }

  private static const Bool[] idChars
  static
  {
    map := Bool[,]
    map.fill(false, 127)
    for (i:='a'; i<='z'; ++i) map[i] = true
    for (i:='A'; i<='Z'; ++i) map[i] = true
    for (i:='0'; i<='9'; ++i) map[i] = true
    map['_'] = true
    map[':'] = true
    map['-'] = true
    map['.'] = true
    map['~'] = true
    idChars = map
  }

  // TODO: parse old RecId format
  @NoDoc static Ref? fromRecIdStr(Str s, Bool checked := true)
  {
    try
    {
      // 01234567890123456
      // tttttttt-rrrrrrrr
      if (Env.cur.runtime == "js") return Ref(s)
      if (s.size == 17 && s[8] == '-')
      {
        time := s[0..7].toInt(16)
        rand := s[9..16].toInt(16)
        handle := time.and(0xffff_ffff).shiftl(32).or(rand.and(0xffff_ffff))
        return makeHandle(handle)
      }
    }
    catch (ParseErr e) { if (checked) throw e }
    catch (Err e) {}
    if (checked) throw ParseErr("Invalid RecId: $s")
    return null
  }

  internal Str toZinc()
  {
    if (disVal == null) return toCode
    return StrBuf(1+id.size+8+disVal.size)
            .addChar('@').add(id)
            .addChar(' ').add(disVal.toCode).toStr
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  ** Null ref is "@null"
  const static Ref nullRef := Ref("null")

  ** Default is `nullRef`
  const static Ref defVal := nullRef
}

