// History:
//   11 8 12 Creation

using fwt
using camembert

**
** MenuBar
**
class AxonMenu : Menu
{
  new make(Frame frame)
  {
    text = "Axon"
    update(frame)
  }

  ** Update according to license status
  internal Void update(Frame frame)
  {
    removeAll

    add(MenuItem{ it.command = NewAxonPrj{}.asCommand })
  }
}


