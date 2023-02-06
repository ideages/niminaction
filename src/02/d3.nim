type
  Od = object
    i:int
  
  OP = ptr Od


proc `=destroy`(obj:var Od) =
  echo "析构 Od"

import random

proc test = 
  for i in 0..5:
    if rand(9) > 1:
      var o:OP = create(Od)
      o.i = rand(100)
      echo o.i * o.i


randomize()
test()

# nim c -r --mm:orc d3.nim

# 类是值对象。字符串和seq 也是值类型
# 引用对象需要new
# 析构不适用于 指针类型，这个不会调用destroy


