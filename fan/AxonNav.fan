// History:
//  Jan 04 13 tcolar Creation
//
using camembert

class AxonNav : Nav
{
  override ItemList list
  override File root

  // TODO: make a setting collapseLimit
  new make(Frame frame, File dir, NavItemBuilder navBuilder, FileItem? curItem)
    : super(collapseLimit, navBuilder)
  {
    this.collapseLimit = 9999
    listWidth := 270

    root = dir
    files := [AxonItem.fromFile(dir)]
    findItems(dir, files)
    list = ItemList(frame, files, listWidth)
    highlight(curItem.file)
  }
}