
using build

class Build : BuildPod
{
  new make()
  {
    podName = "camAxonPlugin"
    summary = "Axon projects support plugin for camembert (Skyspark Axon projects)"
    depends = ["sys 1.0",
               "concurrent 1.0",
               "gfx 1.0",
               "fwt 1.0",
               "util 1.0+",
               "web 1.0+",
               "camembert 1.1.0+",
               "netColarUtils 1.0.0+",
               "netColarUI 1.0.0+",
               // haystack 2.0+ required
               //"haystack 2.0+" -> using bundled version for now
               "dom 1.0+",
               ]
    version = Version("1.0.0")
    srcDirs = [`fan/`, `fan/licensing/`, `fan/haystack/`]
    resDirs = [,]
    meta    = ["license.name" : "Free Trial / Commercial",
                "org.name"   : "Status 302 LLC",
                "camembert.plugin" : "AxonPlugin"]
    docSrc  = true
  }
}