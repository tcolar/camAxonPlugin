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

  override Space? createSpace(Sys sys, File file)
  {
    if( ! licOk)
      return null

    File dir := file.isDir ? file : file.parent
    if(file.ext == "axon" ||
        file.name == AxonConn.fileName.toStr ||
        dir.plus(AxonConn.fileName).exists
      )
        return AxonSpace(sys, dir, file)
    return null
  }

  override Int? spacePriority() { 75 }

  override Item? projectItem(File dir, Int indent)
  {
    if( ! licOk)
      return null

    if(dir.isDir && dir.plus(AxonConn.fileName).exists)
      return AxonItem.fromFile(dir)
    return null
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