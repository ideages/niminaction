## 这是世界上最好的模块
## 我们有很多文档
##
##
## 例子
## ======
##
## 下面显示些例子:
##
##
## 将两个数字相加
## ---------------------------
##
## .. code-block:: nim
##
##   doAssert add(5, 5) == 10
## 
## 处理文件
## ----------------------------
## .. code-block:: nim
##   let fileName = "system.nim"
##   doAssert pFile(fileName) == ""
## 
##

proc add*(a, b: int): int =
  ## 将整数 ``a`` 和整数 ``b`` 相加后返回结果。
  return a + b

proc pFile*(fileName:string):string =
  ## 根据文件名处理每个文件。
  return ""


# nim doc doc.nim
