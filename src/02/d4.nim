type
  Od = object
    i:int
  OP1 = ptr Od
  OP = distinct ptr Od


proc `=destroy`(obj:var OP) =
  echo "析构 OP"

import random

proc test = 
  for i in 0..5:
    if rand(9) > 1:
      var o:OP = OP(create(Od))
      OP1(o).i = rand(100)
      echo OP1(o).i * OP1(o).i


randomize()
test()

# nim c -r --mm:orc d4.nim
# nim c -r --mm:orc --expandArc:test d4.nim

# 类是值对象。字符串和seq 也是值类型
# 引用对象需要new
# 可以析构 distinct 的指针类型，可以销毁C库中分配的 指针数据。


# --expandArc: test

# block :tmp:
#   var i
#   mixin inc
#   var res = 0
#   block :tmp_1:
#     while res <= 5:
#       i = T(res)
#       if (
#         1 < rand(9)):
#         var
#           o
#           :tmpD
#         try:
#           o = create(Od, 1)
#           o.i_1 = rand(100)
#           echo [
#             :tmpD = `$`(o.i_1 * o.i_1)
#             :tmpD]
#         finally:
#           `=destroy`(:tmpD)
#           `=destroy_1`(o)
#       inc(res, 1)
# -- end of expandArc ------------------------