import os, parseutils

proc parse(line: string, domainCode, pageTitle: var string,
    countViews, totalSize: var int) =
  var i = 0
  domainCode.setLen(0)
  i.inc parseUntil(line, domainCode, {' '}, i)
  i.inc
  pageTitle.setLen(0)
  i.inc parseUntil(line, pageTitle, {' '}, i)
  i.inc
  countViews = 0
  i.inc parseInt(line, countViews, i)
  i.inc
  totalSize = 0
  i.inc parseInt(line, totalSize, i)

proc readPageCounts(filename: string) =
  var domainCode = ""
  var pageTitle = ""
  var countViews = 0
  var totalSize = 0
  var mostPopular = ("", "", 0, 0)  
  for line in filename.lines:
    parse(line, domainCode, pageTitle, countViews, totalSize)
    if domainCode == "en" and countViews > mostPopular[2]:
      mostPopular = (domainCode, pageTitle, countViews, totalSize)


  echo("Most popular is: ", mostPopular)

when isMainModule:
  const file = "pagecounts-20160101-050000"
  let filename = getCurrentDir() / file
  readPageCounts(filename)

# nim c -d:release sequential_counts3.nim
# output Most popular is: ("en", "Main_Page", 271165, 4791147476)
#  time ./sequential_counts3
# ./sequential_counts3  2.53s user 0.06s system 99% cpu 2.592 total