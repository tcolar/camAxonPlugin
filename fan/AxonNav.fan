// History:
//  Jan 04 13 tcolar Creation
//
using camembert

class AxonNav : Nav
{
  override ItemList items
  override File root

  // TODO: make a setting collapseLimit
  new make(Frame frame, File dir, NavItemBuilder navBuilder, Item? curItem)
    : super(collapseLimit, navBuilder)
  {
    this.collapseLimit = 9999
    listWidth := 270

    root = dir
    files := [Item(dir)]
    findItems(dir, files)
    items = ItemList(frame, files, listWidth)
    highlight(curItem.file)
  }
}