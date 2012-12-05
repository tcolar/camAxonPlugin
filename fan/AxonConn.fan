// History:
//   12 4 12 - Thibaut Colar Creation

using skyspark
using folio
using camembert
using netColarUtils
using fwt

**
** SkysparkConn : Connection to a skyspark server
**
@Serializable
class AxonConn
{
  const Str project
  const Str user
  const Str host

  ** Not going to store the pasword for now, but just keep it in mem for session
  @Transient Str? password

  @Transient Client? client

  @Transient DateTime? lastSync

  @Transient File dir // where this Conn is stored / synced too

  new make(|This| f) {f(this)}

  private Void connect()
  {
    client = Client.open(`http://$host/api/$project`, user, password)
  }

  Grid? sync(Frame frame)
  {
    if(password == null)
    {
      password = Dialog.openPromptStr(frame, "Password for project $project:")
    }
    if(client == null)
    {
      try
        connect()
      catch(AuthErr ae)
        Dialog.openWarn(frame, "Connection to Skyspark failed. Please edit it and try to syc again.", ae)
      catch(IOErr ae)
        Dialog.openWarn(frame, "Connection to Skyspark failed. Please edit it and try to syc again.", ae)
    }
    if(client == null)
    {
      password = null
      return null
    }
    else
    {
      // ok, we are good, do the sync
      results := client.eval("readAll(func)")
      results.onChange |Results| {echo("Results changed !!")}
      try
        return results.get(1min)
      catch(TimeoutErr e)
      {
        Dialog.openWarn(frame, "Skyspark sync Timed out !", e)
        return null
      }
      // TODO: if no errors and if server polling enabled, kick off polling (actor)
    }
  }

  Void save(File to)
  {
    JsonUtils.save(to.out, this)
  }
}