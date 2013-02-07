// History:
//  Jan 09 13 tcolar Creation
//

using camembert
using gfx
using fwt

**
** AxonGridItem
**
@Serializable
class AxonGridItem : Item
{
  const Unsafe grid
  static const Image gridIcon := Image(`fan://icons/x16/chartArea.png`)

  new makeGrid(Grid grid)
    : super.makeStr("Result Grid ($grid.size rows, $grid.cols.size cols). Click to view.")
  {
    this.grid = Unsafe(grid)
    this.icon = gridIcon
  }

  override Void selected(Frame frame)
  {
    HaystackGridDisplayer(grid.val, frame).open
  }
}