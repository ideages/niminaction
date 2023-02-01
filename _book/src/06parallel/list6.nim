import threadpool

proc crash(): string =
  raise newException(Exception, "Crash")

let lineFlowVar = spawn crash()
sync()


# nim c -r --threads:on list6.nim

# Error: unhandled exception: Crash [Exception]
# Error: execution of an external program failed: '/Users/macpro/program/nim-in-action/src/06parallel/list6 '