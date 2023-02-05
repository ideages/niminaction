type
  myseq*[T] = object
    len, cap: int
    data: ptr UncheckedArray[T]

proc `=destroy`*[T](x: var myseq[T]) =
  if x.data != nil:
    for i in 0..<x.len: `=destroy`(x.data[i])
    dealloc(x.data)

proc `=trace`[T](x: var myseq[T]; env: pointer) =
  # `=trace` allows the cycle collector `--mm:orc`
  # to understand how to trace the object graph.
  if x.data != nil:
    for i in 0..<x.len: `=trace`(x.data[i], env)

proc `=copy`*[T](a: var myseq[T]; b: myseq[T]) =
  # do nothing for self-assignments:
  #复制，相同类型，
  if a.data == b.data: return
  `=destroy`(a)
  wasMoved(a)
  a.len = b.len
  a.cap = b.cap
  if b.data != nil:
    a.data = cast[typeof(a.data)](alloc(a.cap * sizeof(T)))
    for i in 0..<a.len:
      a.data[i] = b.data[i]

proc `=sink`*[T](a: var myseq[T]; b: myseq[T]) =
  # move assignment, optional.，移动赋值，可选。如果没有，编译器会用 ·=destroy和copyMEM代替。
  # Compiler is using `=destroy` and `copyMem` when not provided
  `=destroy`(a)
  wasMoved(a)
  a.len = b.len
  a.cap = b.cap
  a.data = b.data

proc add*[T](x: var myseq[T]; y: sink T) =
  # 添加一群元素
  if x.len >= x.cap:
    x.cap = max(x.len + 1, x.cap * 2)
    x.data = cast[typeof(x.data)](realloc(x.data, x.cap * sizeof(T)))
  x.data[x.len] = y
  inc x.len

proc `[]`*[T](x: myseq[T]; i: Natural): lent T =
  assert i < x.len
  x.data[i]

proc `[]=`*[T](x: var myseq[T]; i: Natural; y: sink T) =
  assert i < x.len
  x.data[i] = y

proc createSeq*[T](elems: varargs[T]): myseq[T] =
  result.cap = elems.len
  result.len = elems.len
  result.data = cast[typeof(result.data)](alloc(result.cap * sizeof(T)))
  for i in 0..<result.len: result.data[i] = elems[i]

proc len*[T](x: myseq[T]): int {.inline.} = x.len


when isMainModule:
  # var seqss = createSeq("")
  echo "OK"