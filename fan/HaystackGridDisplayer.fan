// History:
//   12 6 12 - Thibaut Colar Creation

using fwt
//using haystack
using gfx
using netColarUI

**
** HaytackGridDisplayer
** Display Grid results tabulated in a window
**
class HaystackGridDisplayer
{
  private Window win

  new make(Grid g, Window parent)
  {
    win = Window(parent)
    {
      size = Size(parent.size.w-50, parent.size.h-50)
      title = "Grid results"
      content  = InsetPane{
        content = ScrollPane{
          content = Table
          {
            model = HaystackGridModel(g)
            onAction.add |Event e| {showRow(e, g)}
          }
        }
      }
    }
  }

  Void open()
  {
    win.open
  }

  Void showRow(Event event, Grid grid)
  {
    gp:= GridPane{
      it. numCols = 2
    }
    row := grid.get(event.index)
    grid.cols.each |col|
    {
      item := row.get(col.name)
      gp.add(Label{it.text=col.dis})
      // Using cutom area that allows cut and paste
      gp.add(RichTextArea(item != null ? item.toStr : "null"))
    }
    Window(win)
    {
      size = Size(win.size.w-100, win.size.h-100)
      title = "Row details"
      content  = InsetPane{
        content = ScrollPane{
          content = gp
        }
      }
    }.open
  }
}

class HaystackGridModel : TableModel
{
  Grid grid

  new make(Grid g)
  {
    this.grid = g
  }

  override Int numCols() {grid.cols.size}

  override Int numRows() {grid.size}

  override Str header(Int col) {grid.colDisNames[col]}

  override Str text(Int col, Int row)
  {
    val := grid[row][grid.colNames[col]]
    return val == null ? "null" : val.toStr
  }
}