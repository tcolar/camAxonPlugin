// History:
//   12 6 12 - Thibaut Colar Creation

using fwt
using folio
using fresco
using gfx
using netColarUI

**
** FolioGridDisplayer
** Display Grid results tabulated in a window
**
class FolioGridDisplayer
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
            model = GridTableModel(g)
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

