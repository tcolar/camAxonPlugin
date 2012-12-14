// History:
//   12 5 12 - Thibaut Colar Creation

using concurrent
using fwt
using camembert

**
** AxonSyncActor
** Actor to intercat with Axon / Skyspark backend
**
const class AxonSyncActor : Actor
{
  const File projectFolder
  const File dataFile
  const File logFile

  new make(File folder) : super(ActorPool())
  {
    this.projectFolder = folder
    dataFile = projectFolder + `_sync_items.obj`
    logFile = projectFolder + `_sync.log`
  }

  ** Sync from/to server
  override Obj? receive(Obj? obj)
  {
    AxonActorData? data
    try
    {
      data = (AxonActorData) obj
      result := doReceive(data)
      data.runCallback(result)
      return result
    }
    catch(Err e)
    {
      log(e, data)
      if(e is IOErr)
      {
        reconnect(data)
      }
      return e
    }
    return null
  }

  Obj? doReceive(AxonActorData data)
  {
    action := data.action

    if(action == AxonActorAction.needsPassword)
    {
      return ! Actor.locals.containsKey("camAxon.conn")
    }
    if(action == AxonActorAction.evalLast)
    {
      return AxonEvalStack.read.items.peek
    }
    if(action == AxonActorAction.evalUp)
    {
      return AxonEvalStack.read.up
    }
    if(action == AxonActorAction.evalDown)
    {
      return AxonEvalStack.read.down
    }
    if(action == AxonActorAction.autoStatus)
    {
      return Actor.locals.containsKey("camAxon.auto")
    }
    if(action == AxonActorAction.autoOn)
    {
      Actor.locals["camAxon.auto"] = true
      return null
    }
    if(action == AxonActorAction.autoOff)
    {
      Actor.locals.remove("camAxon.auto")
      return null
    }

    // Actions that need a connection
    connect(data.password, data)

    conn := (AxonConn) Actor.locals["camAxon.conn"]

    switch(action)
    {
      case(AxonActorAction.deleteFunc):
         log("Deleting from server function : $data.deleteFunc ", data)
         del := "commit(diff(read(func and name==$data.deleteFunc.toCode), null, {remove}))"
         return Unsafe(conn.client.eval(del).get)

      case(AxonActorAction.eval):
        log("Eval: $data.eval ...", data)
        AxonEvalStack.read.append(data.eval)
        result := Unsafe(conn.client.eval(data.eval))
        return result

      case(AxonActorAction.sync):
        auto := Actor.locals.containsKey("camAxon.auto")
        try
          sync(conn, data)
        catch(Err syncErr)
        {
          log(syncErr, data)
          if(! auto) throw syncErr
        }
        if(auto)
          sendLater(2sec, data) // autosync
        return null

      default:
        throw Err("Unexpected action: $action !")
    }
  }

  ** Connects the client (if not already connected)
  Void connect(Str password, AxonActorData data)
  {
   if(! Actor.locals.containsKey("camAxon.conn"))
    {
      Actor.locals.remove("camAxon.data")
      c := AxonConn.load(projectFolder + AxonConn.fileName)
      log("Connecting to $c ...", data)
      c.password = password
      c.connect
      Actor.locals["camAxon.conn"] = c
      log("Connected !", data)
    }
  }

  ** Reconnect ... useful in case we got an IoErr, such as if we got logged out
  Void reconnect(AxonActorData? data)
  {
    if(data != null)
    {
      log("Trying to reconnect ...", data)
      conn := (AxonConn?) Actor.locals["camAxon.conn"]
      if(conn != null)
      {
        conn?.connect
        log("Reconnected !", data)
      }
    }
  }

  ** Runs project synchronization with the server
  AxonSyncInfo sync(AxonConn conn, AxonActorData data)
  {
    File[] sentItems := [,]
    File[] createdItems := [,]
    File[] updatedItems := [,]

    Str:AxonSyncItem items := [:]

    if(Actor.locals.containsKey("camAxon.data"))
      items = (Str:AxonSyncItem) Actor.locals["camAxon.data"]
    else
    {
      // first sync since app was started, try to reuse last run data
      if(dataFile.exists)
      try
        items = dataFile.readObj()
      catch(Err e) {e.trace}
    }

    grid := conn.client.eval(Str<|readAll(func).keepCols(["id", "mod", "name", "src"])|>).get(1min)

    conn.dir.list.each |f|
    {
      if(f.ext == "axon")
      {
        if( ! items.containsKey(f.basename))
        {
          items[f.basename] = AxonSyncItem {it.path = relPath(f); it.localTs = f.modified.ticks; it.remoteTs = f.modified.ticks}
        }
      }
    }

    // sync from server files that don't exist locally or have a newer timestamp
    grid.each |r|
    {
      f := conn.dir + `${r->name}.axon`
      // new or updated file
      if( ! items.containsKey(r->name) || r->mod->ticks > items[r->name].remoteTs)
      {
        if(f.exists)
          updatedItems.add(f)
        else
          createdItems.add(f)
        log("Pulling from sever : $f", data)
        f.out.print(r->src).close
        items[r->name] = AxonSyncItem {it.path =  relPath(f); it.localTs = f.modified.ticks; it.remoteTs = r->mod->ticks}
      }
    }

    // Push new files
    conn.dir.list.each |f|
    {
      if(f.ext == "axon")
      {
        r := grid.find |row| {row->name == f.basename}
        if(r==null ||  f.modified.ticks > items[f.basename].localTs)
        {
          sentItems.add(f)
          log("Sending to server : $f", data)

          src  := f.readAllStr
          expr := r == null ?
              "commit(diff(null, {name: $f.basename.toCode, src: $src.toCode, mod: $f.modified.ticks, func}, {add}))"
            : "commit(diff(read(func and name==$f.basename.toCode), {src: $src.toCode}))"
          grid2 := conn.client.eval(expr).get
          meta := grid2.meta
          // Really should never happen unless inernal error
          if(meta.has("errTrace"))
            log("Error grid: " + meta["errTrace"], data)

          newMod := grid2.first->mod->ticks

          items[f.basename] = AxonSyncItem {it.path =  relPath(f); it.localTs = f.modified.ticks; it.remoteTs = newMod}
        }
      }
    }
    Actor.locals["camAxon.data"] = items

    // if any changes write the sync data file so it can get picked up if app is restarted
    if( ! updatedItems.isEmpty || ! createdItems.isEmpty || ! sentItems.isEmpty)
      dataFile.writeObj(items)

    return AxonSyncInfo
    {
      updatedFiles = updatedItems
      createdFiles = createdItems
      sentFiles  = sentItems
    }
  }

  AxonEvalStack evalStack()
  {
    if(! Actor.locals.containsKey("camAxon.evalStack"))
      Actor.locals["camAxon.evalStack"] = AxonEvalStack()
    return Actor.locals["camAxon.evalStack"]
  }

  ** Log to a file in the project for debugging / tracing
  ** Obj would typically be an Err or string
  Void log(Obj obj, AxonActorData data)
  {
     data.runCallback(obj)

     text := (obj is Err) ?
           ((Err) obj).traceToStr
           : obj.toStr

     // if file is old start over
     if(logFile.exists && DateTime.now - logFile.modified > 1hr)
      logFile.delete
     if(! logFile.exists)
      logFile.create
     out := logFile.out(true)
     try
       out.printLine("${DateTime.now.toLocale} - $text")
     catch(Err e)
      e.trace
     finally
      out.close
  }

  ** File path relative to project
  ** using this so that if project is relocated AxonSycItem serialization stays valid
  Str relPath(File f)
  {
    return f.normalize.uri.relTo(projectFolder.normalize.uri).toStr
  }
}

***********************************************************************
** Actor data object
**************************************************************************

@Serializable
const class AxonActorData
{
  const AxonActorAction action
  const Str? password := null
  const Str? eval := null
  const Sys? sys := null
  const Str? deleteFunc := null

  const |Obj?|? callback := null

  new make(|This| f)
  {
    f(this)
  }

  Void runCallback(Obj? results)
  {
    if(callback != null)
    {
      Desktop.callAsync |->|
      {
        callback(results)
      }
    }
  }
}

** SyncActor Actions enum
enum class AxonActorAction
{
  needsPassword, sync, eval, evalUp, evalDown, evalLast,
  autoOn, autoOff, autoStatus, deleteFunc
}

**************************************************************************
** AxonSyncItem
**************************************************************************

** Data about a synced file
** Note: serilized to obj, be careful if changing
@Serializable
internal const class AxonSyncItem
{
  ** Path relative to project folder
  const Str path
  const Int? localTs
  const Int? remoteTs

  new make(|This| f) {f(this)}

  // Return a new instance for the same file but with an updated ts (both local & remote)
  AxonSyncItem withTs(Int ts)
  {
    return AxonSyncItem
    {
      it.path = this.path
      it.localTs = ts
      it.remoteTs = ts
    }
  }

  // New instance with new remoteTs
  AxonSyncItem withLocalTs(Int ts)
  {
    return AxonSyncItem
    {
      it.path = this.path
      it.localTs = ts
      it.remoteTs = this.remoteTs
    }
  }
}

**************************************************************************
** Eval stack
**************************************************************************
const class AxonEvalStack
{
  const Str[] items
  const Int index

  new make(Str[] items := ["readAll(ahu)"], Int index := 0)
  {
    this.items = items
    this.index = index
  }

  Str up()
  {
    i := index <= 0 ? 0 : index -1
    Actor.locals["camAxon.evalStack"] = AxonEvalStack(items, i)
    return items[i]
  }

  Str down()
  {
    i := index >= items.size - 2 ? items.size - 1 : index + 1
    Actor.locals["camAxon.evalStack"] = AxonEvalStack(items, i)
    return items[i]
  }

  Void append(Str eval)
  {
    if(eval != items.peek)
      Actor.locals["camAxon.evalStack"] = AxonEvalStack(items.dup.add(eval), index + 1)
  }

  static AxonEvalStack read()
  {
    if(! Actor.locals.containsKey("camAxon.evalStack"))
      Actor.locals["camAxon.evalStack"] = AxonEvalStack()
    return Actor.locals["camAxon.evalStack"]
  }
}

**************************************************************************
** AxonActors
**************************************************************************

** Keep the map of actors per project/space
** Can't be held in space since those are reloaded all the time
class AxonActors
{
  // map of project / actor
  Uri:AxonSyncActor actors := [:]

  AxonSyncActor forProject(File dir)
  {
    uri := dir.normalize.uri
    if( ! actors.containsKey(uri))
      actors[uri] = AxonSyncActor(dir)
    return actors[uri]
  }
}