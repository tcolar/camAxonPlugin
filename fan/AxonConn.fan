// History:
//   12 4 12 - Thibaut Colar Creation

using skyspark
using folio
using camembert
using netColarUtils
using fwt

**
** AxonConn : Connection to a axon functions on a skyspark server
**
@Serializable
class AxonConn
{
  const Str project
  const Str user
  const Str host

  ** Not going to store the password for now, but just ask and  keep it in mem for session
  @Transient Str? password

  @Transient Client? client

  @Transient DateTime? lastSync

  @Transient File? dir // where this Conn is stored / synced too

  @Transient static const Uri fileName := `axon_conn.props`

  new make(|This| f) {f(this)}

  ** Connects to skysaprk
  ** Will throw an Err if fails
  Void connect()
  {
    if(client == null)
    {
      client = Client.open(`http://$host/api/$project`, user, password)
    }
  }

  Void save(File to)
  {
    JsonUtils.save(to.out, this)
  }

  static AxonConn load(File from)
  {
    conn := (AxonConn) JsonUtils.load(from.in, AxonConn#)
    conn.dir = from.parent
    return conn
  }
}