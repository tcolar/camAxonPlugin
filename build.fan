
using build

class Build : BuildPod
{
  new make()
  {
    podName = "camAxonPlugin"
    summary = "(Alpha) Axon projects support plugin for camembert (Skyspark Axon projects)"
    depends = ["sys 1.0",
               "concurrent 1.0",
               "gfx 1.0",
               "fwt 1.0",
               "util 1.0+",
               "web 1.0+",
               "dom 1.0+",
               "netColarUtils 1.0.5+",
               "netColarUI 1.0.0+",
               "camFantomPlugin 1.1.4+",
               "camembert 1.1.4+",
               ]
    version = Version("0.1.4")
    srcDirs = [`fan/`, `fan/licensing/`, `fan/haystack/`]
    resDirs = [,]
    meta    = ["license.name" : "Free Trial / Commercial",
                "org.uri"   : "http://www.status302.com/",
                "camembert.plugin" : "AxonPlugin"]
    docSrc  = true
  }
}