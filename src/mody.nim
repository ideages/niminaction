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
proc processCode(line:string):string=
  result = line
  result = result.replace("❶","  # <1>")
  result = result.replace("❷","  # <2>")
  result = result.replace("❸","  # <3>")
  result = result.replace("❹","  # <4>")
  result = result.replace("❺","  # <4>")
  result = result.replace("❻","  # <6>")
  result = result.replace("❼","  # <7>")
  result = result.replace("❽","  # <8>")
  result = result.replace("❾","  # <9>")
  result = result.replace("❿","  # <10>")
  return result

proc processNote(line:string):string=
  result = line
  result = result.replace("❶","<1>")
  result = result.replace("❷","<2>")
  result = result.replace("❸","<3>")
  result = result.replace("❹","<4>")
  result = result.replace("❺","<5>")
  result = result.replace("❻","<6>")
  result = result.replace("❼","<7>")
  result = result.replace("❽","<8>")
  result = result.replace("❾","<9>")
  result = result.replace("❿","<10>")


proc processLine(line:string):string =
  # lin = "saaa`jjasx`jjjj"
  # assert  "abcd".find("c") == 2
  # var start = 0
  # scanp()
  result = line
  if line.find("``")>=0 or line.find("```")>=0:
    # echo "注释：" & line
    return 
  var start = line.find("`",0)
  var next = start + 1
  var inVar = false
  while start >= 0:
    next = line.find("`",start+1)
    let cen = next - start + 2
    let ss = " " & line[start..next] & " "
    echo ss
    start = line.find("`",next+1)


    # if line[start+1].isAlphaAscii:
      
      
    # result = line[0..start+1]
    # line.replace"`"," `")



    
  # var list = line.split("`")
  # for row in list:
  #   if row.len < 3:
  #     result.add(row)
  #     continue
  #   if row[0].isAlphaAscii and row[^1].isAlphaAscii:
  #     #echo row
  #     result.add(" `")
  #     result.add(row)
  #     result.add("` ")
  #   else:
  #     result.add(row)


when isMainModule:
  # withFile(txt, "01.md", fmWrite):
  #   for lin in txt.lines:
  # #     # lin.
  #     # lin = "saaa`jjasx`jjjj"
  #     assert  "abcd".find("c") == 2
  #     let a = lin.find("`")
  #     let b = lin.find("`")
  #     # "a".center(5) == "  a  "
  #     echo lin
  let l = "saaa`jjasx`jjjj"
  echo processLine(l)
  let ls = "saaa中文`jjasx`合集jjjj"
  echo processLine(ls)
  var ib = false
  withFile(txt, "./01.md", fmRead):
    for lin in txt.lines:
      if lin.find("```") == 0:
        if lin.len >= 3 and ib == false:
          ib = true
        else:
          # 是代码开始了。
          ib = false

      if ib:
        # assert false
        # in 代码内部 ❶
        discard processCode(lin)
        # echo lin
      else:
        #echo processNote(lin)
        if lin.find("`") >= 0:
          discard processLine(lin)
        


  # txt.writeLine("line 1")
  # txt.writeLine("line 2")

