//
// Copyright (c) 2009, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   22 Aug 09  Brian Frank  Creation
//

using web

**
** Client manages a network connection to a haystack server.
**
class Client
{
  ** Haystack version of the server (set in make upon connection)
  Str version := "1.0"

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Open with URI of project such as "http://host/api/myProj/".
  ** Throw IOErr for network/connection error or `AuthErr` if
  ** credentials are not authenticated.
  **
  static Client open(Uri uri, Str username, Str password)
  {
    // normalize and check URI
    uri = uri.plusSlash
    if (uri.scheme != "http") throw ArgErr("Only http: URIs supported: $uri")

    // authenticate with server
    cookie := ApiAuth(uri, username, password).auth

    // we're in
    return make(uri, username, cookie)
  }

  private new make(Uri uri, Str username, Str cookie)
  {
    this.uri = uri
    this.username = username
    this.cookie = cookie
    try
    {
      dict := about
      version = dict["haystackVersion"] ?: "1.0"
    }
    catch(Err e)
    {
      /*IF about fails then it's probably 1.0 barring unexpected issue. Not an ideal version test.*/
    }
  }

//////////////////////////////////////////////////////////////////////////
// Identity
//////////////////////////////////////////////////////////////////////////

  **
  ** URI of project path such as "http://host/api/myProj/".
  ** This URI always ends in a trailing slash.
  **
  const Uri uri

  ** Username used for authentication
  const Str username

  **
  ** Return uri.toStr
  **
  override Str toStr() { uri.toStr }

//////////////////////////////////////////////////////////////////////////
// Requests
//////////////////////////////////////////////////////////////////////////

  **
  ** Call "about" operation to query server summary info.
  **
  Dict about()
  {
    call("about", Etc.makeEmptyGrid).first
  }

  **
  ** Call "read" operation to read a record by its identifier.  If the
  ** record is not found then return null or raise UnknownRecException
  ** based on checked flag.  Raise `CallErr` if server returns error grid.
  ** Also see [Rest API]`docSkySpark::Ops#read`.
  **
  Dict? readById(Ref id, Bool checked := true)
  {
    req := Etc.makeListGrid(null, "id", null, [id])
    res := call("read", req)
    if (!res.isEmpty && res.first.has("id")) return res.first
    if (checked) throw UnknownRecErr(id.toCode)
    return null
  }

  **
  ** Call "read" operation to read a list of records by their identifiers.
  ** Return a grid where each row of the grid maps to the respective
  ** id list (indexes line up).  If checked is true and any one of the
  ** ids cannot be resolved then raise UnknownRecErr for first id not
  ** resolved.  If checked is false, then each id not found has a row
  ** where every cell is null.  Raise `CallErr` if server returns error
  ** grid.  Also see [Rest API]`docSkySpark::Ops#read`.
  **
  Grid readByIds(Ref[] ids, Bool checked := true)
  {
    req := Etc.makeListGrid(null, "id", null, ids)
    res := call("read", req)
    if (checked) res.each |r, i| { if (r.missing("id")) throw UnknownRecErr(ids[i].toStr) }
    return res
  }

  **
  ** Call "read" operation to read a record that matches the given filter.
  ** If there is more than one record, then it is undefined which one is
  ** returned.  If there are no matches then return null or raise
  ** UnknownRecException based on checked flag.  Raise `CallErr` if server
  ** returns error grid.  Also see [Rest API]`docSkySpark::Ops#read`.
  **
  Dict? read(Str filter, Bool checked := true)
  {
    req := Etc.makeListsGrid(null, ["filter", "limit"], null, [[filter, Number.one]])
    res := call("read", req)
    if (!res.isEmpty) return res.first
    if (checked) throw UnknownRecErr(filter)
    return null
  }

  **
  ** Call "read" operation to read a record all recs which match the
  ** given filter.  Raise `CallErr` if server returns error grid.
  ** Also see [Rest API]`docSkySpark::Ops#read`.
  **
  Grid readAll(Str filter)
  {
    req := Etc.makeListGrid(null, "filter", null, [filter])
    return call("read", req)
  }

  **
  ** Evaluate an Axon expression and return results as Grid.
  ** Raise `CallErr` if server returns error grid.
  ** Also see [Rest API]`docSkySpark::Ops#eval`.
  **
  Grid eval(Str expr)
  {
    call("eval", Etc.makeListGrid(null, "expr", null, [expr]))
  }

  **
  ** Evaluate a list of expressions.  The req parameter must be
  ** 'Str[]' of Axon expressions or a correctly formatted `Grid`
  ** with 'expr' column.
  **
  ** A separate grid is returned for each row in the request.  If checked
  ** is false, then this call does *not* automatically check for error
  ** grids - client code must individual check each grid for partial
  ** failures using `Grid.isErr`.  If checked is true and one of the
  ** requests failed, then raise `CallErr` for first failure.
  **
  ** Also see [Rest API]`docSkySpark::Ops#evalAll`.
  **
  Grid[] evalAll(Obj req, Bool checked := true)
  {
    // construct grid request
    reqGrid := req as Grid
    if (reqGrid == null)
    {
      if (req isnot List) throw ArgErr("Expected Grid or Str[]")
      reqGrid = Etc.makeListGrid(null, "expr", null, req)
    }

    // make request and parse response
    reqStr := ZincWriter.gridToStr(reqGrid, version)
    resStr := doCall("evalAll", reqStr)
    res := ZincReader(resStr.in).readGrids

    // check for errors
    if (checked) res.each |g| { if (g.isErr) throw CallErr(g) }
    return res
  }

  **
  ** Commit a set of diffs.  The req parameter must be a grid
  ** with a "commit" tag in the grid.meta.  The rows are the
  ** items to commit.  Return result as Grid or or raise `CallErr`
  ** if server returns error grid.
  **
  ** Also see [Rest API]`docSkySpark::Ops#commit`.
  **
  ** Examples:
  **   // add new record
  **   tags := ["site":Marker.val, "dis":"Example Site"])
  **   toCommit := Etc.makeDictGrid(["commit":"add"], tags)
  **   client.commit(toCommit)
  **
  **   // update dis tag
  **   changes := ["id": orig->id, "mod":orig->mod, "dis": "New dis"]
  **   toCommit := Etc.makeDictGrid(["commit":"update"], changes)
  **   client.commit(toCommit)
  **
  Grid commit(Grid req)
  {
    if (req.meta.missing("commit")) throw ArgErr("Must specified grid.meta commit tag")
    return call("commit", req)
  }

  **
  ** Call the given REST operation with its request grid and
  ** return the response grid.  If req is null, then an empty
  ** grid used for request.  If the checked flag is true and server
  ** returns an error grid, then raise `CallErr`, otherwise return
  ** the grid itself.
  **
  Grid call(Str op, Grid? req := null, Bool checked := true)
  {
    if (req == null) req = Etc.makeEmptyGrid
    Str reqStr := ZincWriter.gridToStr(req, version)
    Str resStr := doCall(op, reqStr)
    Grid res   := ZincReader(resStr.in).readGrid
    if (checked && res.isErr) throw CallErr(res)
    return res
  }

  private Str doCall(Str op, Str req)
  {
    c := WebClient(this.uri + op.toUri)
    c.reqHeaders["Cookie"] = cookie
    c.postStr(req)
    return c.resIn.readAllStr
  }

//////////////////////////////////////////////////////////////////////////
// Main
//////////////////////////////////////////////////////////////////////////

  // set ApiAuth.debug = true to dump authentication cycle
  @NoDoc static Void main(Str[] args)
  {
    if (args.size < 3) { echo("usage: <uri> <user> <pass>"); return }
    c := Client.open(args[0].toUri, args[1], args[2])
    a := c.about
    echo("\nPing successful: $c.uri\n")
    Etc.dictNames(a).sort.each |n| { echo("$n: ".padr(18) + a[n]) }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private const Str cookie
}

**************************************************************************
** ApiAuth
**************************************************************************

**
** ApiAuth is used to authenticate a user/password combination using
** the REST API authentication mechanism.
**
@NoDoc
class ApiAuth
{
  **
  ** Construct with a protected URI space such as "/api/{proj}"
  **
  new make(Uri uri, Str user, Str pass)
  {
    this.uri  = uri
    this.user = user
    this.pass = pass
  }

  **
  ** Authenticate the username, password against the URI.  If successful
  ** then return the session cookie.  If authentication failed then throw
  ** AuthErr.
  **
  Str auth()
  {
    readAuthUri
    if (cookie != null) return cookie
    readAuthInfo
    computeDigest
    authenticate
    return cookie
  }

  private Void readAuthUri()
  {
    // make request to URI with redirects disabled
    c := WebClient(uri.plus(`about`))
    c.followRedirects = false
    send(c, false, null)

    // 4xx or 5xx
    if (c.resCode % 100 >= 4) throw IOErr("HTTP error code: $c.resCode")

    // if client returned 200, then it is not running with security
    if (c.resCode == 200) { this.cookie = "fanws:test"; return }

    // get URI from required header
    this.authUri = c.resHeaders["Folio-Auth-Api-Uri"]   ?: throw AuthErr("Missing 'Folio-Auth-Api-Uri' header [$c.resCode]")
  }

  private Void readAuthInfo()
  {
    c := WebClient(uri + authUri.toUri  + `?$user`)
    response := send(c, true, null)
    this.authInfo = parseAuthProps(response)
  }

  private Void computeDigest()
  {
    this.nonce = authInfo["nonce"] ?: throw AuthErr("Missing 'nonce' in auth info")
    this.salt  = authInfo["userSalt"] ?: throw AuthErr("Missing 'userSalt' in auth info")

    // compute salted hmac
    hmac := Buf().print("$user:$salt").hmac("SHA-1", pass.toBuf).toBase64

    // now compute login digest using nonce
    this.digest = "${hmac}:${nonce}".toBuf.toDigest("SHA-1").toBase64
  }

  private Void authenticate()
  {
    // post back to auth URI
    c := WebClient(uri + authUri.toUri  + `?$user`)
    response := send(c, true, "nonce:$nonce\ndigest:$digest")

    if (c.resCode != 200) throw AuthErr("Authentication failed")

    info := parseAuthProps(response)
    this.cookie = info["cookie"] ?: throw AuthErr("Missing 'cookie'")
  }

  private static Str:Str parseAuthProps(Str text)
  {
    map := Str:Str[:]
    text.splitLines.each |line|
    {
      line = line.trim
      if (line.isEmpty) return
      colon := line.index(":")
      map[line[0..<colon].trim] = line[colon+1..-1].trim
    }
    return map
  }

  private Str? send(WebClient c, Bool get, Str? post)
  {
    try
    {
      // if posting, translate to body buffer and get web client setup
      Buf? body
      if (post != null)
      {
        body = Buf().print(post).flip
        c.reqMethod = "POST"
        c.reqHeaders["Content-Type"] = "text/plain; charset=utf-8"
        c.reqHeaders["Content-Length"] = body.size.toStr
      }

      // debug dump request
      if (debug)
      {
        method := post == null ? "GET" : "POST"
        echo("$method $c.reqUri.relToAuth HTTP/1.1")
        echo("Host: $c.reqUri.host")
        c.reqHeaders.each |v, k| { echo("$k: $v") }
        echo
        if (post != null) { echo(post); echo }
      }

      // make request
      if (post == null)
      {
        c.writeReq.readRes
      }
      else
      {
        c.writeReq
        c.reqOut.writeBuf(body).close
        c.readRes
      }

      // read response
      response := get && c.resCode == 200 ? c.resIn.readAllStr : null

      // debug dump response
      if (debug)
      {
        echo("HTTP/1.1 $c.resCode $c.resPhrase")
        c.resHeaders.each |v, k| { echo("$k: $v") }
        echo
        if (response != null) { echo(response); echo }
      }

      return response
    }
    finally c.close
  }

  private static const Bool debug := false

  private const Uri uri            // constructor
  private const Str user           // constructor
  private const Str pass           // constructor
  private Str? authUri             // readAuthApiUri
  private Str:Str authInfo := [:]  // readAuthApiInfo
  private Str? nonce               // computeDigest
  private Str? salt                // computeDigest
  private Str? digest              // computeDigest
  private Str? cookie              // authenticate
}