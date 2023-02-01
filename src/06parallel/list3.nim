var data = "Hello World"

proc countData(param: string) {.thread.} =
  for i in 0..< param.len:   
    stdout.write($i)          
  echo()                      

var threads: array[2, Thread[string]]               
createThread[string](threads[0], countData, data)   
createThread[string](threads[1], countData, data)   
joinThreads(threads)   