// History:
//   12 5 12 - Thibaut Colar Creation

using camembert
using fwt
using gfx
using concurrent
using folio

**
** AxonSpace
**
@Serializable
const class AxonSpace : Space
{
  const AxonSyncActor syncActor

  new make(Sys sys, File dir, File? file) : super(sys)
  {
    if (!dir.exists) throw Err("Dir doesn't exist: $dir")
    if (!dir.isDir) throw Err("Not a dir: $dir")

    this.name = dir.name

    this.dir  = dir.normalize
    this.file = file ?: dir + AxonConn.fileName

    AxonActors acts := sys.plugins[Pod.of(this).name]->actors->val
    syncActor = acts.forProject(dir)
  }

  static const Image funcIcon := Image(`fan://camAxonPlugin/res/func.png`)

  ** Project name
  const Str name

  ** Project directory
  const File dir

  ** Proect / conn file
  const File file

  override Str dis() { name }

  override Image icon() { funcIcon }

  override File? curFile() { file }

  override PodInfo? curPod() { null }

  override TypeInfo? curType() {null}

  override Str:Str saveSession()
  {
    ["dir":dir.uri.toStr, "file":file.uri.toStr]
  }

  static Space loadSession(Sys sys, Str:Str props)
  {
  // sys.plugin......
    make(sys, props.getOrThrow("dir").toUri.toFile,
      props.get("file")?.toUri?.toFile)
  }

  override Int match(Item item)
  {
    // add 1000 so always preferred over filespace
    if (!FileUtil.contains(this.dir, item.file))
      return 0
    return 1000
  }

  override This goto(Item item)
  {
    make(sys, dir, item.file)
  }

  override Widget onLoad(Frame frame)
  {
    frame.history.push(this, Item(file))
    return EdgePane
    {
      left = InsetPane(0, 5, 0, 5)
      {
        EdgePane
        {
          top = Button
          {
            it.text = "Synchronize"
            it.onAction.add |e| {sync}
          }
          center = makeFileNav(frame)
        },
      }
      center = InsetPane(0, 5, 0, 0) { View.makeBest(frame, file), }
    }
  }

  private Widget makeFileNav(Frame frame)
  {
    items := [Item(dir)]
    findItems(dir, items)
    list := ItemList(frame, items, 280)
    items.eachWhile |item, index -> Bool?|
    {
      if(item.toStr == Item.makeFile(file).toStr)
      {
        list.highlight = item
        list.scrollToLine(index>=5 ? index-5 : 0)
        return true
      }
      return null
    }
    return list
  }

  private Void findItems(File dir, Item[] results)
  {
    dir.listFiles.sort |a, b| {a.name  <=> b.name}.each |f|
    {
      results.add(axonItem(f))
    }
  }

  static Item axonItem(File file)
  {
    return Item
    {
      it.file = file
      it.dis = file.name
      it.icon = (file.ext == "axon" || file.isDir) ? funcIcon : Theme.fileToIcon(file)
    }
  }

  Void sync()
  {
    Str? pass := ""
    if(syncActor.send(["needsPassword"]).get == true)
      pass = Dialog.openPromptStr(sys.frame, "Password for project $dir.name:")

    if(pass == null)
      return

    result := syncActor.send(["run", pass]).get
    if(result!=null && result.typeof.fits(Err#))
    {
      e := (Err)result
      Dialog.openWarn(sys.frame, e.toStr, e)
    }
    else
    {
      sys.frame.reload
    }
  }

  override Void onUnload()
  {
    syncActor.pool.stop
  }
}

