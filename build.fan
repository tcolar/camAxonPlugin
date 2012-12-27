
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
               "skyspark 1.0+",
               "folio 1.0+",
               "util 1.0+",
               "fresco 1.0+",
               "web 1.0+",
               "camembert 1.0.9+",
               "netColarUtils 1.0.0+",
               "netColarUI 1.0.0+"]
    srcDirs = [`fan/`, `fan/licensing/`]
    resDirs = [,]
    meta    = ["license.name" : "Commercial",
                "org.name"   : "Status 302 LLC",
                "camembert.plugin" : "AxonPlugin"]
    docSrc  = true
  }
}