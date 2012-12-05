// History:
//   11 8 12 Creation
using camembert

**
** AxonPlugin
**
const class AxonPlugin : Plugin
{
  override Void onFrameReady(Frame frame)
  {
    frame.menuBar.add(AxonMenu(frame))
  }
}