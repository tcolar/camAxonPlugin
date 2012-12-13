// History:
//   12 12 12 Thibaut Colar Creation

using camembert
using folio
using gfx

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
      FolioGridDisplayer(grid.val, frame).open
    else
      super.selected(frame)
  }
}