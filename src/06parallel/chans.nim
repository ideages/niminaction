import os, threadpool

var chan:Channel[string]
open(chan)

proc sayHello() =
  sleep(1000)           
  chan.send("Hello!")

spawn sayHello()        
doAssert chan.recv() == "Hello!"   

# nim c -r --threads:on chans.nim