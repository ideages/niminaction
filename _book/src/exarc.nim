proc main = 
  let mystr = stdin.readLine()

  case mystr
  of "hello":
    echo "Nice to meet you!"
  of "bye":
    echo "Goodbye!"
    quit()
  else:
    discard

main()

# nim c --gc:arc --expandArc:main exarc.nim

#[
--expandArc: main

var mystr
try:
  mystr = readLine(stdin)
  case mystr
  of "hello":
    echo ["Nice to meet you!"]
  of "bye":
    echo ["Goodbye!"]
    quit(0)
  else:
    discard
finally:
  `=destroy`(mystr)
-- end of expandArc ------------------------
]#