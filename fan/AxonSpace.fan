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
    evalText := Text
    {
      data := AxonActorData {action=AxonActorAction.evalLast}
      it.text = (Str) syncActor.send(data).get
    }
    evalText.onKeyUp.add |Event e| {evalKeyUp(e, evalText)}
    evalText.onAction.add |e| {eval(evalText.text)}
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
      center = InsetPane(0, 5, 0, 0)
      {
        EdgePane
        {
          center = View.makeBest(frame, file)
          bottom = EdgePane{left = Label{it.text="Eval:"}; center = evalText}
        },
      }
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

  ** Sync the local project with the server
  Void sync()
  {
    pass := getPass
    if(pass == null)
      return // cancelled

    data := AxonActorData {action=AxonActorAction.sync; password=pass}
    result := syncActor.send(data).get
    showActorResults(result)
    sys.frame.reload
  }

  ** Run an eval on the server and show the results
  ** TODO: run async ... but UI refresh are tricky (Not on UI thread business)
  Void eval(Str toEval)
  {
    pass := getPass
    if(pass == null)
      return // cancelled

    data := AxonActorData {action=AxonActorAction.eval; password=pass; it.eval=toEval}
    showActorResults(syncActor.send(data).get)
    // todo: allow/implement up and down arrows in eval field
  }

  ** Get the connection password. Ask user for it if we don't have it yet
  ** Returns null if cancel was pressed on dialog
  Str? getPass()
  {
    Str? pass := ""
    data := AxonActorData {action=AxonActorAction.needsPassword; password=pass}
    result := syncActor.send(data).get
    showActorResults(result, true)
    if(result == true)
      pass = Dialog.openPromptStr(sys.frame, "Password for project $dir.name:")
    return pass
  }

  ** Dispplay call results to user
  Void showActorResults(Obj? result, Bool errorOnly := false)
  {
    if(result == null) return
    if(errorOnly && ! (result is Err)) return

    if(result is Unsafe)
      showActorResults((result as Unsafe).val)
    else if(result is Result)
      showActorResults((result as Result).get)
    else if(result is Err)
    {
      e := result as Err
      Dialog.openWarn(sys.frame, e.toStr, e)
    }
    else if(result is Grid)
    {
      g := result as Grid
      meta := g.meta
      if(meta.has("errTrace"))
        Dialog.openWarn(sys.frame, meta["dis"], meta["errTrace"])
      else
        FolioGridDisplayer(g, sys.frame).open
    }
  }

  ** Provides eval history navigation
  Void evalKeyUp(Event event, Text eval)
  {
    if(event.key == Key.up)
    {
      data := AxonActorData {action=AxonActorAction.evalUp}
      eval.text = (Str) syncActor.send(data).get
    }
    if(event.key == Key.down)
    {
      data := AxonActorData {action=AxonActorAction.evalDown}
      eval.text = (Str) syncActor.send(data).get
    }
  }
}

