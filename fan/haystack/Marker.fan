//
// Copyright (c) 2009, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   7 Oct 09  Brian Frank  Creation
//

**
** Marker is the singleton which indicates a marker tag with no value.
**
@Js
@Serializable { simple = true }
const class Marker
{
  const static Marker val := Marker()

  static Marker fromStr(Str s) { val }

  private new make() {}

  ** Return "marker"
  override Str toStr() { "marker" }

  ** If true return Marker.val else null
  static Marker? fromBool(Bool b) { b ? val : null }
}