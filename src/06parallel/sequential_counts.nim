import os   
proc readPageCounts(filename: string) =   
  for line in filename.lines:   
    echo(line)   

when isMainModule:   
  const file = "pagecounts-20160101-050000"   
  let filename = getCurrentDir() / file   
  readPageCounts(filename)  
  