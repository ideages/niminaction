import macros
import std/[strutils, strscans]

template withFile(f: untyped, filename: string, mode: FileMode,
                  body: untyped) =
  let fn = filename
  var f: File
  if open(f, fn, mode):
    try:
      body
    finally:
      close(f)
  else:
    quit("cannot open: " & fn)

const secMask = "{==+==}"

# ##
# {==+==}
# # Summary
# {==+==}
# # 摘要
# {==+==}


# {==+==}
# [Introduction](index.md)
# {==+==}
# [简介](index.md)
# {==+==}

# ##
proc pFile(fileName:string):tuple =
  var cns:string = ""
  var engs:string = ""
  withFile(txt, fileName, fmRead):
    # var secOK = false
    var secValue = 0
    for lin in txt.lines:
      if lin.strip == secMask:
        secValue = secValue + 1
      elif secValue == 1:
        ## secV = 1 and line not mask: is English
        engs.add(lin)
        engs.add("\r\n")
        ## sec is Chinese
      elif secValue == 2:
        cns.add(lin)
        cns.add("\r\n")  
      elif secValue == 3:
        # sec End
        engs.add("\r\n")
        cns.add("\r\n")
        secValue = 0
    #endFor
  #end with
  result = (cns,engs)
        
      

proc writeFile(fs:string,fileName:string)=
  withFile(txt, fileName, fmWrite):
    txt.write(fs)

when isMainModule:
  var files:seq[string]
  # files = @["SUMMARY_cn.md","index_cn.md","faq_cn.md"]
  # files = @["2020-12-08-introducing-orc_cn","2020-10-15-introduction-to-arc-orc-in-nim_cn"]
  # files = @["09a_cn.adoc","2022-11-11-a-cost-model-for-nim_cn.md"]
  # files = @["nim-memory_cn.adoc","2021-11-15-zen-of-nim_cn.md"]
  # files.add("nim_nogc_cn.md")
  # files.add("destructors_cn.md")
  files.add("2021-11-15-zen-of-nim_cn.md")
  for fileName in files:
    # let localfile = "../cnbook/" & fileName & ".md"
    # let mmd = "../merge/" & fileName[0..^4] & ".md"
    let localfile = "../cnbook/" & fileName
    let mmd = "../merge/" & fileName 
    # let mmde = "./me" & fileName
    #echo localfile,mmd

    var (fs,es) = pFile(localfile)
    writeFile(fs,mmd)
    # writeFile(es,mmde)

    # pandoc -f markdown -t asciidoc -o 01.adoc m01.md
    # let cmd = "pandoc -f markdown -t asciidoc -o m" & fileName[0..1] & ".adoc m" & fileName
    # echo cmd

#  nim c -r --mm:arc meg.nim
# nim md2html 
# nim rst2htm 