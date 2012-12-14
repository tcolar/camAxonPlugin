// History:
//   12 12 12 Thibaut Colar Creation

using camembert
using folio
using gfx
using fwt

**
** AxonItem
** Custom item for axon files /results items
**
const class AxonItem : Item
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
      it.icon = (file.ext == "axon" || file.isDir) ?
             funcIcon
           : Theme.fileToIcon(file)
    }
  }

  static AxonItem fromGrid(Grid grid, AxonSpace space)
  {
    AxonItem
    {
      it.space = space
      it.grid = Unsafe(grid)
      it.icon = gridIcon
      it.dis = "Result Grid ($grid.size rows, $grid.cols.size cols). Click to view."
    }
  }

  override Void selected(Frame frame)
  {
    if(grid != null)
      FolioGridDisplayer(grid.val, frame).open
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
        it.text = "Find in \"$file.name\""
        it.onAction.add |e|
          { (frame.sys.commands.find as FindCmd).find(file) }
      },
      MenuItem
      {
        dir := file.isDir ? file : file.parent
        it.text = "New file in \"$dir.name\""
        it.onAction.add |e|
          { (frame.sys.commands.newFile as NewFileCmd).newFile(dir, "mewFunc.axon", frame) }
      },

      MenuItem
      {
        it.text = "Delete \"$file.name\""
        it.onAction.add |e|
        {
          (frame.sys.commands.delete as DeleteFileCmd).delFile(file, frame)
          askServerDelete(frame, file, "Delete")
          frame.goto(this) // refresh
        }
      },
      MenuItem
      {
        it.text = "Rename/Move \"$file.name\""
        it.onAction.add |e|
        {
          (frame.sys.commands.move as MoveFileCmd).moveFile(file, frame)
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