//
// Copyright (c) 2009, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   29 Aug 09  Brian Frank  Creation
//

**
** UnknownNameErr is thrown when `Dict.trap` or `Grid.col` fails
** to resolve a name.
**
@Js
const class UnknownNameErr : Err
{
  ** Construct with message and optional cause.
  new make(Str? msg, Err? cause := null) : super(msg, cause) {}
}

**
** UnknownRecErr is thrown when a rec cannot be resolved.
**
@Js
const class UnknownRecErr : Err
{
  ** Construct with message and optional cause.
  new make(Str? msg, Err? cause := null) : super(msg, cause) {}
}

**
** UnitErr indicates an operation between two incompatible units
**
@Js
const class UnitErr : Err
{
  ** Construct with message and optional cause.
  new make(Str? msg, Err? cause := null) : super(msg, cause) {}
}

**
** CallErr is raised when a server returns an error grid from
** a client call to a REST operation.
**
@Js
const class CallErr : Err
{
  new make(Grid errGrid) : super(errGrid.meta.dis) { this.meta = errGrid.meta }

  ** Grid.meta from the error grid response
  const Dict meta
}

**
** Authentication error.
**
@Js
const class AuthErr : Err
{
  new make(Str? msg, Err? cause := null) : super(msg, cause) {}
}