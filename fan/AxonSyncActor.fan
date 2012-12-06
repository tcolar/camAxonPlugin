// History:
//   12 5 12 - Thibaut Colar Creation

using concurrent
using fwt

**
** AxonSyncActor
** Actor that keeps a project axon functions sync'ed
**
const class AxonSyncActor : Actor
{
  const File projectFolder

  new make(File folder) : super(ActorPool())
  {
    this.projectFolder = folder
  }

  ** Sync from/to server
  ** Returns the Err in case of error, null otherwise
  override Obj? receive(Obj? obj)
  {
    Str:AxonSyncItem items := [:]

    try
    {
      data := (List) obj
      action := (Str) data[0]

      if(action=="needsPassword")
        return ! Actor.locals.containsKey("camAxon.conn")

      if(! Actor.locals.containsKey("camAxon.conn"))
      {
        Actor.locals.remove("camAxon.data")

        c := AxonConn.load(projectFolder + AxonConn.fileName)

        c.password = (Str) data[1]

        c.connect

        Actor.locals["camAxon.conn"] = c
      }

      conn := (AxonConn) Actor.locals["camAxon.conn"]

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

      // todo: push new files
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
    catch(Err e)
    {
      e.trace
      return Err("Skyspark sync failed and stopped !", e)
    }
    return null//items
  }
}

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