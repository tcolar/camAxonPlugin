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
    Text password := Text {it.password = true}

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
        Label{text="Password:"}, password,
      }
    }

    if (Dialog.ok != dialog.open) return

    destDir := Uri(folder.text).plusSlash.plusName(project.text, true)
    FileUtils.mkDirs(destDir)

    conn := AxonConn
    {
      it.dir = destDir.toFile
      it.host = host.text
      it.password = password.text
      it.project = project.text
      it.user = user.text
    }

    conn.save(File(destDir+`axon_conn.props`))

    grid := conn.sync(frame)
    grid?.each |row| {echo("Row: $row")}
  }

  new make(|This| f) {f(this)}
}