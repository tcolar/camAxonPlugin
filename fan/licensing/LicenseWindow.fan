// History:
//  Dec 27 12 tcolar Creation
//

using fwt

**
** LicenseWindow
**
 class LicenseWindow : Dialog
{
  new make(Window? parent) : super(parent)
  {
    title = "Licensing"
  }

  ** Update from license
  internal This update(File licFile)
  {
    license := License(licFile)

    Button[] buttons := [,]

    request := Button{
      it.text = "Request License / Trial"
      onAction.add |e| {request(licFile)}
    }
    fetch := Button{
      it.text = "(Re)Fetch License"
      onAction.add |e| {fetch(licFile)}
    }
    purchase := Button{
      it.text = "Purchase"
      // TODO
    }
    close := Button{
      it.text = "Close"
      onAction.add |e| {close}
    }

    Widget? info
    if(license.status == LicenseStatus.none)
    {
      info = Label{it.text = "No License installed !"}
      buttons.add(request)
    }
    else if(license.status == LicenseStatus.expired)
    {
      info = GridPane
      {
        numCols = 2
        Label{it.text = "Licensed EXPIRED since: "},
        Label{it.text = DateTime.makeTicks(license.data.validUntil).toLocale},
        Label{it.text = "Hash key: "}, Label{it.text = license.data.hashKey},
      }
      buttons.add(fetch)
      buttons.add(purchase)
    }
    else if(license.status == LicenseStatus.valid)
    {
      info = GridPane
      {
        numCols = 2
        Label{it.text = "Product"}, Label{it.text = license.data.product},
        Label{it.text = "Issued on:"}, Label{it.text = DateTime.makeTicks(license.data.issueTime).toLocale},
        Label{it.text = "Valid until:"}, Label{it.text = DateTime.makeTicks(license.data.validUntil).toLocale},
        Label{it.text = "Type:"}, Label{it.text = license.data.type},
        Label{it.text = "Hash key: "}, Label{it.text = license.data.hashKey},
      }
      buttons.add(purchase)
      buttons.add(fetch)
    }
    else
    { //invalid or unexpected status
      info = Label{it.text = "INVALID license !"}
      buttons.add(fetch)
    }

    buttons.add(close)

    content := EdgePane
    {
      center = info
      bottom = GridPane{numCols = buttons.size}.addAll(buttons)
    }

    body = content

    relayout
    repaint

    return this
  }

  Void request(File licFile)
  {
    name := Text{}
    email := Text{}

    Dialog? dialog

    submit := Button
    {
      it.text = "Request Trial License"
      it.onAction.add |e|
      {
        dialog.close
        fetch(licFile, ["name" : name.text, "email" : email.text])
      }
    }

    dialog = Dialog(parent)
    {
      it.title = "License request"
      it.body = EdgePane
      {
        center = GridPane
        {
          numCols = 2
          Label{it.text = "Your Name:"}, name,
          Label{it.text = "Email:"}, email,
        }
        bottom = submit
      }
    }

    dialog.open
  }

  Void fetch(File licFile, Str:Str info := [:])
  {
    md5 := Buf().print(MacAddressFinder().find).toDigest("MD5").toHex

    try
    {
      LicenseData.fetch(licFile, License.productName, md5, info)
      Dialog.openInfo(this, "The License was installed, please restart the application.")
    }
    catch(Err e){
      Dialog.openInfo(this, "Failed to retrieve the license.")
    }

    close
  }
}

