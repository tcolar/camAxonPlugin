// History:
//   12 7 12 Creation

//using haystack
using camembert

**
** AxonIndexer : Index/parse axon data(trio funcs and tags)
**
class AxonIndexer
{

  ** TrioInfo keyed by pod name
  Str:TrioInfo trioData(File[] rootDirs)
  {
    Str:TrioInfo info := [:]

    rootDirs.each
    {
      dir := findPodDir(it)
      if(dir != null)
      {
        dir.listFiles.findAll{it.ext=="pod"}.each |pod|
        {
          Str:FuncInfo funcs := [:]
          Str:TagInfo tags := [:]
          pn := pod.basename
          Zip.open(pod).contents.findAll{ext=="trio"}.each |file|
          {
            TrioReader(file.in).eachRec |dict|
            {
              if(dict.has("tag"))
              {
                tags[dict["tag"].toStr] = TagInfo(pn, toStrMap(dict))
              }
              if(dict.has("func"))
              {
                funcs[dict["name"]] = FuncInfo(pn, toStrMap(dict))
              }
            }
          }
          if(! tags.isEmpty || ! funcs.isEmpty)
            info[pn] = TrioInfo(pn, tags, funcs)
        }
      }
    }

    return info
  }

  Str:Str toStrMap(Dict dict)
  {
    Str:Str map:= [:]
    dict.each|obj, str|
    {
      map[str] = obj == null ? null : obj.toStr
    }
    return map
  }

  File? findPodDir(File dir)
  {
    File[] dirs := [,]
    if (!dir.isDir) return null
    name := dir.name.lower
    if (name.startsWith(".")) return null
    if (name == "temp" || name == "tmp" || name == "dist") return null

    if (dir.pathStr.endsWith("lib/fan/"))
    {
      dirs.add(dir)
      return dir
    }

    // recurse
    return dir.listDirs.eachWhile |subDir|
    {
      findPodDir(subDir)
    }
  }

}