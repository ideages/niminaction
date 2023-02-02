import strutils
let line = stdin.readLine()
let result = line.parseInt + 5
echo(line, " + 5 = ", result)

# nim c --debuginfo --linedir:on adder.nim
# nim c --debugger:native adder.nim
# lldb adder
# b adder.nim:3
# run
# ta v
# fr v -a
# print (char*)line_106004->data
