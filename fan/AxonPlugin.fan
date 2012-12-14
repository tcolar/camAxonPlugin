// History:
//   11 8 12 Creation
using camembert

**
** AxonPlugin
**
const class AxonPlugin : Plugin
{
  const Unsafe actors := Unsafe(AxonActors())

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
    // todo: change depending on licensing
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
    // if licene != valid return nothing
    AxonIndexer().trioData(podDirs)
  }
}