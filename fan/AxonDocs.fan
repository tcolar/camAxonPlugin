// History:
//  Feb 06 13 tcolar Creation
//

using camFantomPlugin
using camembert
using gfx
using web

**
** AxonDocs
** Because Axon docs are inside pods, and we already have the fantom plugin indexing that
** This plugin just delegates to the fantom plugin
**
const class AxonDocs : PluginDocs
{
  override const Image? icon := AxonSpace.funcIcon

  ** name of the plugin responsible
  override Str pluginName() {this.typeof.pod.name}

  ** User friendly dsplay name
  override Str dis() {"Axon"}

  ** Return a FileItem for the document matching the current source file (if known)
  ** Query wil be what's in the helPane serach box, ie "fwt::Combo#make" (not prefixed by plugin name)
  override FileItem? findSrc(Str query) {null}

  ** Return html for a given path
  ** Note, the query will be prefixed with the plugin name for example /fantom/fwt::Button
  override Str html(WebReq req, Str query, MatchKind matchKind)
  {
    // Delegate to Fantom pod

    if(query.isEmpty)
      query = "axon-home"

    doc := Sys.cur.plugin(FantomPlugin#.pod.name).docProvider

    return doc.html(req, query, matchKind)
  }
}