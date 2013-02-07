// History:
//   12 13 12 tcolar Creation

using camembert
using netColarUtils

@NoDoc
internal class License
{
  internal static const Str productName := "camAxonPlugin"

  static const File licFile := Sys.confDir + `axonPlugin_license.json`

  internal LicenseData? data
  internal File? file
  internal LicenseStatus status

  new make(File file)
  {
    status =  LicenseStatus.none

    if(! file.exists)
      return

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

  internal Void apply(Frame f)
  {
  }
}


