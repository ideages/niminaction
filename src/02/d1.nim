type
  Od = object
    i:int


proc `=destroy`(obj:var Od) =
  echo "析构 Od"

import random

proc test = 
  for i in 0..5:
    if rand(9) > 1:
      var o:Od
      o.i = rand(100)
      echo o.i * o.i


randomize()
test()

# nim c -r --mm:orc d1.nim

# 类是值对象。字符串和seq 也是值类型
# 引用对象需要new

# 数组，字符串，序列Seq 在Nim 都是值语义。即赋值总是 复制内容。
# 

