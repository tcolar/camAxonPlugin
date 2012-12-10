// History:
//   12 4 12 - Thibaut Colar Creation

using fwt
using camembert
using skyspark
using netColarUtils

const class NewAxonPrj : Cmd
{
  override const Str name := "New Axon project"
  override Void invoke(Event event)
  {
    Text project := Text()
    Text host := Text()
    Text user := Text()

    dirs := frame.sys.options.srcDirs
    dir := dirs.isEmpty ? Env.cur.homeDir.pathStr : File(dirs[0]).pathStr

    Text folder := Text {it.text = dir}

    dialog := Dialog(frame)
    {
      title = "New Axon Project"
      commands = [ok, cancel]
      body = GridPane
      {
        numCols = 2
        Label{text="Sync project into:"}, folder,
        Label{text="Host:"}, host,
        Label{text="Project Name:"}, project,
        Label{text="User:"}, user,
      }
    }

    if (Dialog.ok != dialog.open) return

    destDir := File.os(folder.text).normalize.uri.plusSlash.plusName(project.text, true)
    FileUtils.mkDirs(destDir)

    conn := AxonConn
    {
      it.dir = destDir.toFile
      it.host = host.text
      it.project = project.text
      it.user = user.text
    }

    f := File(destDir + AxonConn.fileName)

    conn.save(f)

    item := AxonSpace.axonItem(f)

    frame.goto(item, true)
  }

  new make(|This| f) {f(this)}
}