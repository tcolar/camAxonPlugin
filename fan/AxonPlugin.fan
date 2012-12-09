// History:
//   11 8 12 Creation
using camembert

**
** AxonPlugin
**
const class AxonPlugin : Plugin
{
  const Unsafe actors := Unsafe(AxonActors())

  override Void onFrameReady(Frame frame)
  {
    (frame.menuBar as MenuBar).plugins.add(AxonMenu(frame))
  }

  override Space? createSpace(Sys sys, File file)
  {
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
    if(dir.isDir && dir.plus(AxonConn.fileName).exists)
      return AxonSpace.axonItem(dir)
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
    AxonIndexer().trioData(podDirs)
  }
}