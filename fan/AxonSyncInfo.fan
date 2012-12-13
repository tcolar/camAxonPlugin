// History:
//   12 12 12 Creation

**
** AxonSyncInfo
** Data about axon function that was done
**
const class AxonSyncInfo
{
  const File[] sentFiles
  const File[] updatedFiles
  const File[] createdFiles
  //File[] deletedFiles

  new make(|This| f) {f(this)}
}