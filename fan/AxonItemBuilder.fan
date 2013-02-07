// History:
//  Jan 04 13 tcolar Creation
//
using camembert

**
** AxonItemBuilder
**
class AxonItemBuilder : NavItemBuilder
{
  override Space space

  new make(Space space) {this.space = space}

  override  Item forFile(File f, Str path, Int indent)
  {
    return AxonItem.makeFile(f)
  }

  override  Item forDir(File f, Str path, Int indent, Bool collapsed)
  {
    return AxonItem.makeFile(f)
  }

  override  Item forProj(Project prj, Str path, Int indent)
  {
    return AxonItem.makeProject(prj)
  }
}