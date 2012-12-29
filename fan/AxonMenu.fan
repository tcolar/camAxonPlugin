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

    license := License(License.licFile)
    if(license.valid)
    {
      add(MenuItem{ it.command = NewAxonPrj{sysRef.val = frame.sys}.asCommand })
    }
    else
    {
    }
    add(MenuItem{ it.command = LicensingCmd{sysRef.val = frame.sys}.asCommand })
    add(MenuItem{ it.command = AboutCmd{sysRef.val = frame.sys}.asCommand })
  }
}


