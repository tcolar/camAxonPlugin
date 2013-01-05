//
// Copyright (c) 2009, SkyFoundry LLC
// All Rights Reserved
//
// History:
//   22 Aug 09  Brian Frank  Creation
//

using dom

@Js
internal class BrowserAuth
{

  **
  ** Login using client user credentials.
  **
  static Void login(Uri authUri)
  {
    doc := Win.cur.doc
    username := (Str)doc.elem("username").val
    password := (Str)doc.elem("password").val

    // disable login
    submit := doc.elem("submit")
    submit.enabled = false
    submit.val = localeLoggingIn

    // get salt/nonce
    HttpReq { uri=authUri + `salt?$username` }.get |res1|
    {
      if (res1.status == 200)
      {
        str   := res1.content.splitLines
        salt  := str[0]
        nonce := str[1]

        hmac := Buf().print("$username:$salt").hmac("SHA-1", password.toBuf).toBase64
        digest := "$hmac:$nonce".toBuf.toDigest("SHA-1").toBase64

        // authenticate
        form := ["username":username, "nonce":nonce, "digest":digest]
        HttpReq { uri=authUri + `login` }.postForm(form) |res2|
        {
          if (res2.status == 200) Win.cur.hyperlink(Uri(res2.content))
          else failed
        }
      }
      else failed
    }
  }

  **
  ** Indicate failed credentials.
  **
  static Void failed()
  {
    // show err
    doc := Win.cur.doc
    err := doc.elem("err")
    err.html = localeInvalidUsernamePassword
    //err.effect.slideDown(100ms)

    // enable login
    submit := doc.elem("submit")
    submit.enabled = true
    submit.val = localeLogin

    // refocus email
    doc.elem("username").focus
  }

  // temp undoc hooks for localization
  internal static const Str localeInvalidUsernamePassword := "Invalid username or password"
  internal static const Str localeLogin := "Login"
  internal static const Str localeLoggingIn := "Logging in"

}