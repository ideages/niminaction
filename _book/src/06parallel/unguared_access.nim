# nim c -r --threads:on unguared_access.nim
# unguared_access.nim(11, 17) Error: unguarded access: counter
import threadpool, locks   

var counterLock: Lock      
initLock(counterLock)      
var counter {.guard: counterLock.} = 0   

proc increment(x: int) =
  for i in 0..<x:
    var value = counter
    value.inc
    counter = value

spawn increment(10_000)
spawn increment(10_000)
sync()
echo(counter)