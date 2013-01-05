// History:
//   12 12 12 Thibaut Colar Creation

using camembert
//using haystack
using gfx
using fwt

**
** AxonItem
** Custom item for axon files /results items
**
const class AxonItem : FileItem
{
  static const Image gridIcon := Image(`fan://icons/x16/chartArea.png`)
  static const Image funcIcon := Image(`fan://icons/x16/func.png`)

  const Unsafe? grid

  new make(|This|? f) : super(f) {}

  static AxonItem fromFile(File file)
  {
    AxonItem
    {
      it.file = file
      it.dis = file.name
      it.icon = (file.ext == "axon") ?
             funcIcon
           : Theme.fileToIcon(file)
      it.isProject = false
    }
  }

  static AxonItem fromProject(File file)
  {
    AxonItem
    {
      it.file = file
      it.dis = file.name
      it.icon = funcIcon
      it.isProject = true
    }
  }

  static AxonItem fromGrid(Grid grid)
  {
    AxonItem
    {
      it.grid = Unsafe(grid)
      it.icon = gridIcon
      it.dis = "Result Grid ($grid.size rows, $grid.cols.size cols). Click to view."
    }
  }

  override Void selected(Frame frame)
  {
    if(grid != null)
      HaystackGridDisplayer(grid.val, frame).open
    else
      super.selected(frame)
  }

  override Menu? popup(Frame frame)
  {
    if (file == null) return null

    if (file.ext != "axon") return super.popup(frame)

    // Menu for Axon items
    return Menu
    {
      MenuItem
      {
        it.text = "Copy name to clipboard"
        it.onAction.add |e|
          { Desktop.clipboard.setText(file.basename) }
      },
      MenuItem
      {
        it.text = "Find in \"$file.name\""
        it.onAction.add |e|
          { (Sys.cur.commands.find as FindCmd).find(file) }
      },
      MenuItem
      {
        dir := file.isDir ? file : file.parent
        it.text = "New file in \"$dir.name\""
        it.onAction.add |e|
          { (Sys.cur.commands.newFile as NewFileCmd).newFile(dir, "mewFunc.axon", frame) }
      },

      MenuItem
      {
        it.text = "Delete \"$file.name\""
        it.onAction.add |e|
        {
          (Sys.cur.commands.delete as DeleteFileCmd).delFile(file, frame)
          askServerDelete(frame, file, "Delete")
          frame.goto(this) // refresh
        }
      },
      MenuItem
      {
        it.text = "Rename/Move \"$file.name\""
        it.onAction.add |e|
        {
          (Sys.cur.commands.move as MoveFileCmd).moveFile(file, frame)
          askServerDelete(frame, file, "Rename")
          frame.goto(this) // refresh
        }
      },
    }
  }

  ** If a file is deleted/renamed, ask if the chnage should be made on the server as well
  ** Note: for rename, we just delete under the old name and sync will recreate under new name
  Void askServerDelete(Frame frame, File file, Str msg)
  {
    answer := Dialog.openQuestion(frame, "$msg $file.basename function on the server as well ?", null, Dialog.yesNo)
    if(answer == Dialog.yes)
    {
      if(frame.curSpace is AxonSpace) // should be
      {
        (frame.curSpace as AxonSpace).remoteDelete(file.basename)
      }
    }
  }
}