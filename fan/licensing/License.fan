// History:
//   12 13 12 Creation
using camembert

@NoDoc
internal const class License
{
  private const LicenseType type
  private const File file

  new make(File file)
  {
    this.file = file
    if(! file.exists)
    {
      type = LicenseType.none
      return
    }

    // todo
    type = LicenseType.invalid
  }

  internal Bool valid()
  {
    return type == LicenseType.trial || type == LicenseType.full
  }

  ** apply the license
  internal Void apply(Frame frame)
  {
  }
}

@NoDoc
internal enum class LicenseType
{
  none, invalid, trial, full
}