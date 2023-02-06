type
  Od = ref object of RootObj
    i:int


proc `=destroy`(obj:var type(Od()[])) =
  echo "析构 ref O"

import random

proc test = 
  for i in 0..5:
    if rand(9) > 1:
      var o:Od = Od() # new OD
      o.i = rand(100)
      echo o.i * o.i


randomize()
test()

# nim c -r --mm:orc d1.nim

# 类是值对象。字符串和seq 也是值类型
# 引用对象需要new