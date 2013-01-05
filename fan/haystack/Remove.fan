//
// Copyright (c) 2010, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   4 Jan 10  Brian Frank  Creation
//

**
** Remove is the singleton which indicates a remove operation.
**
@Js
const class Remove
{
  const static Remove val := Remove()

  private new make() {}

  override Str toStr() { "remove" }
}