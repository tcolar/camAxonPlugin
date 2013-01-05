// History:
//  Jan 04 13 tcolar Creation
//
using camembert

**
** AxonItemBuilder
**
class AxonItemBuilder : NavItemBuilder
{
  override  Item forFile(File f, Str path, Int indent)
  {
    return AxonItem.fromFile(f)
  }

  override  Item forDir(File f, Str path, Int indent, Bool collapsed)
  {
    return AxonItem.fromFile(f)
  }

  override  Item forProj(File f, Str path, Int indent)
  {
    return AxonItem.fromFile(f)
  }
}