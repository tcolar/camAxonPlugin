//
// Copyright (c) 2009, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   22 Dec 09  Brian Frank  Creation
//


**
** Column of a Grid
**
@Js
abstract class Col
{
  **
  ** Programatic name identifier for columm
  **
  abstract Str name()

  **
  ** Deprecated, display is configured by 'meta.dis'
  **
  @Deprecated Str? disVal() { null }

  **
  ** Meta-data for column
  **
  abstract Dict meta()

  **
  ** Display name for columm which is 'meta.dis(null, name)'
  **
  Str dis() { meta.dis(null, name) }

  **
  ** Equality is based on reference
  **
  override final Bool equals(Obj? that) { this === that }

  **
  ** Compare based on name
  **
  override final Int compare(Obj x) { name <=> ((Col)x).name }

  **
  ** String representation is name
  **
  override final Str toStr() { name }
}

**************************************************************************
** ColFormatter
**************************************************************************

**
** Registered by qname on a col with 'formatter' to customize
** formatting of cells under a given column.
**
@Js
@NoDoc
const abstract class ColFormatter
{
  ** Format given column and cell value or return null to use default
  abstract Str? format(Col col, Row row, Obj? val)
}