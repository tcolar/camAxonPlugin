// History:
//   12 5 12 - Thibaut Colar Creation

using concurrent
using fwt

**
** AxonSyncActor
** Actor to intercat with Axon / Skyspark backend
**
const class AxonSyncActor : Actor
{
  const File projectFolder

  new make(File folder) : super(ActorPool())
  {
    this.projectFolder = folder
  }

  ** Sync from/to server
  override Obj? receive(Obj? obj)
  {
    data := (AxonActorData) obj
    try
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
      else
      {
        // Actions that need a connection
        connect(data.password)

        conn := (AxonConn) Actor.locals["camAxon.conn"]

        switch(action)
        {
          case(AxonActorAction.eval):
            AxonEvalStack.read.append(data.eval)
            result := Unsafe(conn.client.eval(data.eval))
            doCallback(data, result)
            return result

          case(AxonActorAction.sync):
            sync(conn)
            doCallback(data, null)
            return null

          default:
            throw Err("Unexpected action: $action !")
        }
      }
    }
    catch(Err e)
    {
      e.trace
      doCallback(data, e)
      return Err("Server communication error !", e)
    }
    doCallback(data, null)
    return null
  }

  Void doCallback(AxonActorData data, Obj? obj)
  {
    data.runCallback(obj)
  }

  ** Connects the client (if not already connected)
  Void connect(Str password)
  {
   if(! Actor.locals.containsKey("camAxon.conn"))
    {
      Actor.locals.remove("camAxon.data")
      c := AxonConn.load(projectFolder + AxonConn.fileName)
      c.password = password
      c.connect
      Actor.locals["camAxon.conn"] = c
    }
   }

  ** Runs project synchronization with the server
  Void sync(AxonConn conn)
  {
    Str:AxonSyncItem items := [:]

    if(Actor.locals.containsKey("camAxon.data"))
      items = (Str:AxonSyncItem) Actor.locals["camAxon.data"]

    grid := conn.client.eval(Str<|readAll(func).keepCols(["id", "mod", "name", "src"])|>).get(1min)

    conn.dir.list.each |f|
    {
      if(f.ext == "axon")
      {
        if( ! items.containsKey(f.basename))
        {
          items[f.basename] = AxonSyncItem {it.file = f.osPath; it.localTs = f.modified; it.remoteTs = f.modified}
        }
      }
    }

    // sync from server files that don't exist locally or have a newer timestamp
    grid.each |r|
    {
      f := conn.dir + `${r->name}.axon`
      // new or updated file
      if( ! items.containsKey(r->name) || r->mod > items[r->name].remoteTs)
      {
        echo("Pulling from sever : $f")
        f.out.print(r->src).close
        items[r->name] = AxonSyncItem {it.file = f.osPath; it.localTs = f.modified; it.remoteTs = r->mod}
      }
    }

    // Push new files
    conn.dir.list.each |f|
    {
      if(f.ext == "axon")
      {
        r := grid.find |row| {row->name == f.basename}
        if(r==null ||  f.modified > items[f.basename].localTs)
        {
          echo("Sending to server : $f")

          src  := f.readAllStr
          expr := "commit(diff(read(func and name==$f.basename.toCode), {src: $src.toCode}))"
          grid2 := conn.client.eval(expr).get(1min)
          newMod := grid2.first->mod

          items[f.basename] = AxonSyncItem {it.file = f.osPath; it.localTs = f.modified; it.remoteTs = newMod}
        }
      }
    }
    Actor.locals["camAxon.data"] = items
  }

  AxonEvalStack evalStack()
  {
    if(! Actor.locals.containsKey("camAxon.evalStack"))
      Actor.locals["camAxon.evalStack"] = AxonEvalStack()
    return Actor.locals["camAxon.evalStack"]
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
  ** If set, callback.val must contain a function of : |Obj?|
  const Unsafe? callback := null

  new make(|This| f)
  {
    f(this)
  }

  Void runCallback(Obj? results)
  {
    if(callback != null)
    {
       cb := (|Obj?|) callback.val
       cb.call(results)
    }
  }
}

** SyncActor Actions enum
enum class AxonActorAction
{
  needsPassword, sync, eval, evalUp, evalDown, evalLast
}

**************************************************************************
** AxonSyncItem
**************************************************************************

** Data about a synced file
@Serializable
internal const class AxonSyncItem
{
  const Str file
  const DateTime? localTs
  const DateTime? remoteTs

  DateTime fileModif() {return File.os(file).modified}

  new make(|This| f) {f(this)}

  // Return a new instance for the same file but with an updated ts (both local & remote)
  AxonSyncItem withTs(DateTime ts)
  {
    return AxonSyncItem
    {
      it.file = this.file
      it.localTs = ts
      it.remoteTs = ts
    }
  }

  // New instance with new remoteTs
  AxonSyncItem withLocalTs(DateTime ts)
  {
    return AxonSyncItem
    {
      it.file = this.file
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