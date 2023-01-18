var data = "Hello World"               

proc showData() {.thread.} =           
  echo(data)                           

var thread: Thread[void]               
createThread[void](thread, showData)   
joinThread(thread)   


# nim c--threads:on list1.nim
