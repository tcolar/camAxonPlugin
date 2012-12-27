// History:
//  Dec 20 12 tcolar Creation
//
// This class(es) re meant to be copied into the client side
//

using netColarUtils
using web

@NoDoc
@Serializable
internal class LicenseData
{
  Str product
  Int issueTime
  Int validUntil
  Str type
  [Str:Str] info // user, email, host
  Str? hashKey

  new make(|This| f)
  {
    f(this)
  }

  ** Build the hash
  ** Host key is mac address MD5
  @NoDoc
  internal static Str buildHash(LicenseData data, Str hostKey)
  {
    concat := ""
    data.typeof.fields.dup.sort |a,b| {a.name <=> b.name}.each |field|
    {
      if(field.name != "hashKey")
      {
        if(field.name == "info")
          (field.get(data) as Str:Str).each {concat += it}
        else
          concat+= field.get(data).toStr
      }
    }
    return Buf.make.print(hostKey).print("#@302L1ce"+"ns1ng!!").toDigest("MD5").toHex
  }

  ** Check the license is valid on the local machine
  internal LicenseStatus status(Str prd, Str hostMd5)
  {
    if(product != prd)
      return LicenseStatus.invalid
    if(hashKey != buildHash(this, hostMd5))
      return LicenseStatus.invalid
    if(validUntil < DateTime.now.ticks)
      return LicenseStatus.expired
    return LicenseStatus.valid
  }

  static LicenseData load(InStream in)
  {
    return (LicenseData) JsonUtils.load(in, LicenseData#)
  }

  ** Fetch the license from the server
  ** Might throw an Err
  static Void fetch(File dest, Str product, Str hostMd5, Str:Str extra := [:])
  {
    Str:Str data := extra.dup
    data["product"] = product
    data["host"] = Env.cur.host
    data["user"] = Env.cur.user
    data["hostKey"] = hostMd5
    dataStr := Buf().writeObj(data).flip.readAllStr
    echo("dataStr: $dataStr")
    c := WebClient(`http://localhost:8080/fetch`)
    c.postStr(dataStr)
    c.readRes

   // TODO: save to file
  }
}

@NoDoc
internal enum class LicenseStatus
{
  none, invalid, valid, expired
}

