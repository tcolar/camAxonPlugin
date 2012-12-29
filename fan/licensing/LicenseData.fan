// History:
//  Dec 20 12 tcolar Creation
//
// This class(es) are meant to be copied/used on the client side
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
  [Str:Str] info // user, email, host, whatever
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
        {
          dt := field.get(data)  as Str:Str
          dt.keys.sort|a,b| {a<=>b}.each {concat += dt[it]}
        }
        else
          concat+= field.get(data).toStr
      }
    }
    digest := Buf().print(concat).print(hostKey).print("#@302L1ce"+"ns1ng!!").flip.toDigest("MD5").toHex
    return digest
  }

  ** Check the license is valid on the local machine
  @NoDoc
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

  @NoDoc
  static LicenseData load(InStream in)
  {
    return (LicenseData) JsonUtils.load(in, LicenseData#)
  }

  ** Fetch the license from the server
  ** Might throw an Err
  @NoDoc
  static Void fetch(File dest, Str product, Str hostMd5, Str:Str extra := [:])
  {
    Str:Str data := extra.dup
    data["product"] = product
    data["host"] = Env.cur.host
    data["user"] = Env.cur.user
    data["hostKey"] = hostMd5
    dataStr := Buf().writeObj(data).flip.readAllStr
    c := WebClient(`http://lic.status302.com/fetch`)
    c.postStr(dataStr)

    if(c.resCode != 200)
      throw Err("Faied: $c.resStr")

    // write the (json) license to file
    dest.out.printLine(c.resStr).close
  }
}

@NoDoc
internal enum class LicenseStatus
{
  none, invalid, valid, expired
}


