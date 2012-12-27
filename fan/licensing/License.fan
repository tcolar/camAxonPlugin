// History:
//   12 13 12 tcolar Creation

using camembert
using netColarUtils

@NoDoc
internal class License
{
  private static const Str productName := "camAxonPlugin"

  private LicenseData? data
  private File file
  private LicenseStatus status

  new make(File file)
  {
    this.file = file
    if(! file.exists)
      return

    status =  LicenseStatus.none

    try
    {
      data = LicenseData.load(file.in)
      hash := Buf().print(MacAddressFinder().find).toDigest("MD5").toHex
      status = data.status(productName, hash)
    }
    catch(Err e)
    {
      status = LicenseStatus.invalid
      e.trace
    }
  }

  internal Bool valid()
  {
    return status == LicenseStatus.valid
  }

  ** apply the license
  internal Void apply(Frame frame)
  {
  }
}


