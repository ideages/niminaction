# nim c -r --threads:on  parallel_incrementer_chans.nim

import threadpool

var resultChan: Channel[int]      
open(resultChan)    

proc increment(x: int) =
  var counter = 0   
  for i in 0..<x:
    counter.inc
  resultChan.send(counter)        

spawn increment(10_000)
spawn increment(10_000)
sync()              
var total = 0
for i in 0..<resultChan.peek:   
  total.inc resultChan.recv()   
    
echo(total)
