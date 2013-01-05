// History:
//   12 4 12 - Thibaut Colar Creation

using fwt
using camembert
using netColarUtils

const class NewAxonPrj : Cmd
{
  override const Str name := "Import Axon project"
  override Void invoke(Event event)
  {
    Text project := Text()
    Text host := Text()
    Text user := Text()

    dirs := Sys.cur.options.srcDirs
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

    item := AxonItem.fromFile(f)

    frame.goto(item)
  }

  new make(|This| f) {f(this)}
}

const class LicensingCmd : Cmd
{
  override const Str name := "Licensing"
  override Void invoke(Event event)
  {
    LicenseWindow(frame).update(License.licFile).open
  }

  new make(|This| f) {f(this)}
}

const class AboutCmd : Cmd
{
  override const Str name := "About"
  override Void invoke(Event event)
  {
    version := Pod.of(this).version.toStr
    Dialog.openInfo(frame, "Camembert Axon plugin.\n\nVersion:$version\n\nBy Thibaut Colar.\n\nhttp://www.status302.com/",null)
  }

  new make(|This| f) {f(this)}
}