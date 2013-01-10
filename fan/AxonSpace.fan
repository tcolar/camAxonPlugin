// History:
//   12 5 12 - Thibaut Colar Creation

using camembert
using fwt
using gfx
using concurrent
//using haystack

**
** AxonSpace
**
@Serializable
class AxonSpace : BaseSpace
{
  const AxonSyncActor syncActor

  override View? view
  override Nav? nav
  override Image icon() { funcIcon }

  static const Image funcIcon := Image(`fan://icons/x16/func.png`)
  static const Image syncIcon := Image(`fan://icons/x16/sync.png`)
  static const Image helpIcon := Image(`fan://icons/x16/question.png`)
  static const Image errorIcon := Image(`fan://icons/x16/err.png`)

  new make(Frame frame, File dir, File? file := null) :
      super(frame, dir.name, dir.normalize, file)
  {
    if( ! License(License.licFile).valid)
      throw Err("Invalid license")

    AxonActors acts := Sys.cur.plugins[Pod.of(this).name]->actors->val
    syncActor = acts.forProject(dir)

    view = View.makeBest(frame, this.file)
    nav = AxonNav(frame, dir, AxonItemBuilder(this), AxonItem.makeFile(this.file))

    navParent.content = navPane(nav)

    evalText := Text
    {
      data := AxonActorData {action=AxonActorAction.evalLast}
      it.text = (Str) syncActor.send(data).get
    }
    evalText.onKeyUp.add |Event e| {evalKeyUp(e, evalText)}
    evalText.onAction.add |e| {eval(evalText.text)}
    viewParent.content = EdgePane
    {
      center = file == null ? null : View.makeBest(frame, file)
      bottom = EdgePane{left = Label{it.text="Eval:"}; center = evalText}
    }
  }

  override Str:Str saveSession()
  {
    ["dir":dir.uri.toStr, "file":file.uri.toStr]
  }

  static Space loadSession(Frame frame, Str:Str props)
  {
  // sys.plugin......
    make(frame, props.getOrThrow("dir").toUri.toFile,
      props.get("file")?.toUri?.toFile)
  }

  override Int match(FileItem item)
  {
    // add 1000 so always preferred over filespace
    if (!FileUtil.contains(this.dir, item.file))
      return 0
    return 1000
  }

  Pane navPane(Nav nav)
  {
    return EdgePane
    {
      top = EdgePane
      {
        left = GridPane
        {
          numCols = 1
          Button
          {
            it.image = syncIcon
            it.onAction.add |e| {sync(syncActor, dir)}
          },
        }
        right = /*GridPane
        {
          numCols = 2*/
          Button
          {
            // TODO: set selected according to Cur Status of actor
            it.selected = autoStatus()
            it.text = "AutoSync"
            it.mode = ButtonMode.toggle
            it.onAction.add |e| {autoSync()}
          }/*,
          Label{image = syncIcon},
        }*/
      }
      center = nav.list
    }
  }

  override Void updateView(View newView)
  {
    dest := (viewParent.content as EdgePane)
    dest.center = newView
    view = newView
    dest.relayout
  }

  ** Enable / disable autosync
  Void autoSync()
  {
    on := autoStatus()
    if( ! on)
    {
      data := AxonActorData {action=AxonActorAction.autoOn}
      result := syncActor.send(data).get
      log("Auto sync -> on")
      sync(syncActor, dir) // kick off sync
    }
    else
    {
      data := AxonActorData {action=AxonActorAction.autoOff}
      log("Auto sync -> off")
      result := syncActor.send(data).get
    }
  }

  ** log to console
  ** NEEDS TO BE IMMUTABLE - SED IN CALLBACK
  static Void log(Str msg)
  {
    Sys.cur.frame.console.append([Item(msg)])
  }

  ** Sync the local project with the server
  ** NEEDS TO BE IMMUTABLE
  static Void sync(AxonSyncActor syncActor, File dir)
  {
    pass := getPass(syncActor, dir)
    if(pass == null)
      return // cancelled

    log("Sync")
    data := AxonActorData
    {
      action = AxonActorAction.sync
      password = pass
      callback = |Obj? obj|
      {
        if(obj is AxonSyncInfo)
        {
          info := obj as AxonSyncInfo
          if( ! info.createdFiles.isEmpty)
            Sys.cur.frame.curSpace.nav.refresh
        }
        else
          showActorResults(obj)
      }
    }
    syncActor.send(data)
  }

  ** chck current autosync status
  Bool autoStatus()
  {
    data := AxonActorData {action=AxonActorAction.autoStatus}
    return (Bool) syncActor.send(data).get
  }

  ** Run an eval on the server and show the results
  ** TODO: run async ... but UI refresh are tricky (Not on UI thread business)
  Void eval(Str toEval)
  {
    pass := getPass(syncActor, dir)
    if(pass == null)
      return // cancelled

    data := AxonActorData
    {
      callback = |Obj? obj| {showActorResults(obj)}
      action = AxonActorAction.eval
      password = pass
      it.eval = toEval
    }
    syncActor.send(data)
  }

  Void remoteDelete(Str funcName)
  {
    pass := getPass(syncActor, dir)
    if(pass == null)
      return // cancelled

    data := AxonActorData
    {
      callback = |Obj? obj| {showActorResults(obj, true)}
      action = AxonActorAction.deleteFunc
      deleteFunc = funcName
      password = pass
    }
    syncActor.send(data)

  }

  ** Get the connection password. Ask user for it if we don't have it yet
  ** Returns null if cancel was pressed on dialog
  ** NEEDS TO BE IMMUTABLE - SED IN CALLBACK
  static Str? getPass(AxonSyncActor syncActor, File dir)
  {
    Str? pass := ""
    data := AxonActorData {action=AxonActorAction.needsPassword; password=pass}
    result := syncActor.send(data).get
    showActorResults(result, true)
    if(result == true)
      pass = Dialog.openPromptStr(Sys.cur.frame, "Password for project $dir.name:")
    return pass
  }

  ** Display call results to user
  ** Can display error messages and sync thead infos as well
  ** NEEDS TO BE IMMUTABLE - SED IN CALLBACK
  static Void showActorResults(Obj? result, Bool errorOnly := false)
  {
    if(result == null) return
    if(errorOnly && ! (result is Err)) return

    if(result is Unsafe)
      showActorResults((result as Unsafe).val)
    else if(result is Err)
    {
      e := result as Err
      items := [,]
      e.traceToStr.splitLines.each |line|
      {
        items.add(Item.makeStr(line).setIcon(errorIcon))
      }
      Sys.cur.frame.console.append(items)
    }
    else if(result is Grid)
    {
      g := result as Grid
      meta := g.meta
      if(meta.has("errTrace"))
      {
        items := [,]
        (meta["errTrace"] as Str)?.splitLines?.each |line|
        {
          items.add(Item.makeStr(line).setIcon(errorIcon))
        }
        Sys.cur.frame.console.append(items)
      }
      else
        Sys.cur.frame.console.append([AxonGridItem.makeGrid(g)])
    }
    else if(result is Str)
    {
      s := (Str) result
      log(s)
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

