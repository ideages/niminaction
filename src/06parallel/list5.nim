import threadpool, os   

let lineFlowVar = spawn stdin.readLine()   
while not lineFlowVar.isReady:   
  echo("No input received.")     
  echo("Will check again in 5 seconds.")   
  sleep(5000)           

echo("Input received: ", ^lineFlowVar)     


# nim c -r --threads:on list5.nim