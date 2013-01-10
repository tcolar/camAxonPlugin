// History:
//   11 8 12 Creation
using camembert

**
** AxonPlugin
**
const class AxonPlugin : Plugin
{
  const Unsafe actors := Unsafe(AxonActors())

  const Unsafe license

  new make()
  {
    license = Unsafe(License(License.licFile))
  }

  override Void onInit()
  {
    // create axon template if not there yet
    axon := File(`${Options.standard.parent}/axon.tpl`)
    if(! axon.exists)
    {
      axon.create.out.print("/*\nHistory: {date} {user} Creation\n*/\n\n() => do\n  //TODO\nend\n").close
    }
  }

  override Void onFrameReady(Frame frame)
  {
    (frame.menuBar as MenuBar).plugins.add(AxonMenu(frame))
  }

  override FileItem[] projects()
  {
     return [,]
  }

  override Space? createSpace(File prj)
  {
    if( ! licOk)
      return null

    if(prj.isDir && prj.plus(AxonConn.fileName).exists)
      return AxonSpace(Sys.cur.frame, prj)
    return null
  }

  override Int spacePriority(File prjDir)
  {
    if( ! licOk)
      return 0

    if(prjDir.isDir && prjDir.plus(AxonConn.fileName).exists)
      return 75

    return 0
  }

  override Void onShutdown()
  {
    AxonActors act := actors.val
    act.actors.vals.each |a| {a.pool.stop}
  }

  ** Called via Dynamic call
  Str:TrioInfo trioData(File[] podDirs)
  {
    if( ! licOk)
      return [:]

    return AxonIndexer().trioData(podDirs)
  }

  private Bool licOk()
  {
    lic := license.val as License
    if(lic == null) return false
    return lic.valid
  }
}