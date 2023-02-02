import nimprof #(1)
import strutils #(2)

proc ab() =
  echo("Found letter")

proc num() =
  echo("Found number")

proc diff() =
  echo("Found something else")

proc analyse(x: string) =
  var i = 0
  while i < x.len:
    case x[i] #(3)
    of Letters: ab()
    of {'0' .. '9'}: num()
    else: diff()
    i.inc

for i in 0 .. 10000: #(4)
  analyse("uyguhijkmnbdv44354gasuygiuiolknchyqudsayd12635uha")


# nim c --profiler:on --stacktrace:on prof.nim
# nim c --profiler:off --stackTrace:on -d:memProfiler prof.nim