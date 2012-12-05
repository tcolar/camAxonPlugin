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
    add(MenuItem{ it.command = NewAxonPrj{sysRef.val = frame.sys}.asCommand })
    //MenuItem{ it.command = sys.commands.openProject.asCommand},
    //MenuItem{ it.command = sys.commands.newFunction.asCommand},
  }
}


