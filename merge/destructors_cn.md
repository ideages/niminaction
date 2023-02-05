
Nim 析构和移动语义
==================================

Authors Andreas Rumpf
Version 1.6.10
译文：ideages
注意：本文是官方文档的一部分

关于本文档
===================




本文描述了即将推出的 Nim 运行时，它不再使用经典的 GC 算法，而是基于析构函数和移动语义。新的运行时的优点是 Nim 程序可以不关注堆的大小，这样程序更容易编写，也能更有效地利用多个内核。

另外，文件和套接字等不再需要手动 `close` 调用。

本文档旨在为 Nim 中移动语义和析构函数的工作提供一个精确的规范。



解释的例子
==================
使用此处描述的语言机制，自定义 seq 可以写为：

  ```nim
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
    # move assignment, optional.
    # Compiler is using `=destroy` and `copyMem` when not provided
    `=destroy`(a)
    wasMoved(a)
    a.len = b.len
    a.cap = b.cap
    a.data = b.data

  proc add*[T](x: var myseq[T]; y: sink T) =
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
  ```



生命周期跟踪钩子过程
=======================

Nim的标准 `string` 和 `seq` 类型以及其他标准集合的内存管理是通过所谓的"生命周期跟踪钩子"执行的，这些钩子是特定的[类型绑定运算符](https://nimlang.org/docs/manual.html#procedures-type-bound-operators)。

每个（泛型或具体）对象类型 `T` （ `T` 也可以是 `distinct` 类型）都有4个不同的钩子，由编译器隐式调用。

（注意：这里的 `hook` 并是任何类型的动态绑定或运行时间接寻址，隐式调用是静态绑定的，并且可能是内联的。）
  



`=destroy` 钩子
---------------

`=destroy`钩子释放对象的内存并释放其他相关资源。当变量超出范围或在声明他们的例程即将返回时，通过此钩子析构变量。

类型 `T` 的钩子原型需要：

  ```nim
  proc `=destroy`(x: var T)
  ```
常用的  `=destroy`  模式如下：

  ```nim
  proc `=destroy`(x: var T) =
    # first check if 'x' was moved to somewhere else:
    if x.field != nil:
      freeResource(x.field)
  ```




`=sink` 钩子
------------

一个 `=sink` 钩子移动对象，资源从源窃取并传递到目标。通过将对象设置为其默认值（对象的状态初始值），可以确保源的析构函数之后不会释放资源。将对象 `x` 设置回其默认值将写为 `wasMoved（x）` 。如果未提供，编译器将使用 `=destroy` 和 `copyMem` 的组合。这是有效的，因此用户很少需要实现自己的 `=sink` 运算符，只需提供 `=destroy` 和 `=copy` 就足够了，编译器将负责其余的工作。

类型 `T` 的钩子原型需要：

  ```nim
  proc `=sink`(dest: var T; source: T)
  ```

常用的 `=sink` 模式如下：

  ```nim

  proc `=sink`(dest: var T; source: T) =
    `=destroy`(dest)
    wasMoved(dest)
    dest.field = source.field
  ```

**注意**：`=sink` 不需要检查自我复制。

本文档稍后将解释如何处理自我复制。



`=copy` 钩子
------------

Nim 中的普通赋值在概念上复制了这些值。对于无法转换为 `=sink` 操作的赋值，调用 `=copy` 钩子。

类型 `T` 的钩子原型需要：

  ```nim
  proc `=copy`(dest: var T; source: T)
  ```

常用的 `=copy` 模式如下：

  ```nim
  proc `=copy`(dest: var T; source: T) =
    #  保护自我复制 self-assignments:
    if dest.field != source.field:
      `=destroy`(dest)
      wasMoved(dest)
      dest.field = duplicateResource(source.field)
  ```

 `=copy` 过程可以用 `{.error.}` 编译指示。然后，将在编译时阻止任何否则会导致复制的赋值。这看起来像：

  ```nim
  proc `=copy`(dest: var T; source: T) {.error.}
  ```



但是自定义错误消息不会被编译器注入（例如，`{.error: "custom error".}` ）。请注意，在  `{.error.}`  编译指示之前没有 `=` 。



`=trace` 钩子
-------------

自定义的**容器**类型可以通过 `=trace` 钩子支持 Nim 的循环收集器`--mm:orc`。如果容器未实现 `=trace` ，则通过该容器构建的循环数据结构可能会泄漏内存或资源，但不会内存安全不受影响。

类型 `T` 的钩子原型需要：

  ```nim
  proc `=trace`(dest: var T; env: pointer)
  ```



`env` 使用 ORC 来跟踪内部状态，它应该传递给内置调用 `=trace` 的过程。

通常，只有当自定义 `=destroy` 释放手动分配的资源的时候，才需要自定义 `=trace` ，然后，仅当需要用 `--mm:orc`  中断和收集循环引用资源时，即手动分配的资源内的项中有循环引用。然而，目前存在一个相互使用的问题，即首先使用 `=destroy` / `=trace` 中的任何一个都会自动创建另一个版本，然后与创建第二个版本冲突。解决此问题的方法是转发声明第二个 `钩子` ，以防止自动创建。



使用 `=destroy` 和 `=trace` 时的模式如下：

  ```nim
  type
    Test[T] = object
      size: Natural
      arr: ptr UncheckedArray[T] # raw pointer field

  proc makeTest[T](size: Natural): Test[T] = # custom allocation...
    Test[T](size: size, arr: cast[ptr UncheckedArray[T]](alloc0(sizeof(T) * size)))


  proc `=destroy`[T](dest: var Test[T]) =
    if dest.arr != nil:
      for i in 0 ..< dest.size: dest.arr[i].`=destroy`
      dest.arr.dealloc

  proc `=trace`[T](dest: var Test[T]; env: pointer) =
    if dest.arr != nil:
      # trace the `T`'s which may be cyclic
      for i in 0 ..< dest.size: `=trace`(dest.arr[i], env)

  # following may be other custom "hooks" as required...
  ```


**注意**：与其他钩子相比， `=trace` 钩子（仅由 `--mm:orc` 使用）目前更具实验性，还不完善。



移动语义
==============

"移动"可以被视为优化的复制操作。如果以后未用复制操作的源，则可以用移动来替换复制。本文使用 `lastReadOf(x)` 来标识之后不使用 `x` 。此属性由静态控制流分析计算，但也可以通过显式使用 `system.move`  明确执行。



交换 Swap
========

需要检查自我复制，还需要销毁 `=copy` 和 `=sink` 中先前对象，这是处理系统的有力指标。 `system.swap`  作为内置原语，它只需通过 `copyMem` 或类似机制交换所涉及对象中的每个字段。

换句话说， `swap(a, b)` **没有**实现为 `let tmp = move(b); b = move(a); a = move(tmp)`。

这会产生进一步的后果：

* Nim模型不支持包含指向同一对象的指针的对象。否则交换的对象最终将处于不一致的状态。
* Seqs可以在实现中使用 `realloc` 。



Sink 参数
===============

要将变量移动到集合中，通常需要 `sink` 参数。之后不应使用传递给 `sink` 参数的位置。这是通过对控制流图的静态分析来确保的。如果无法证明它是该位置的最后一次使用，则会改为执行复制，然后将此复制传递给sink参数。



sink 参数 *可以*在过程的主体中使用一次，但根本不需要使用。
这样做的原因是，像  `proc put(t: var Table; k: sink Key, v: sink Value)` 应该可以在没有任何进一步重载的情况下实现，如果表中已经存在 `k` ，则 `put` 可能不会拥有 `k` 的所有权。Sink参数启用仿射类型系统，而不是线性类型系统。




采用的静态分析是有限的，只涉及局部变量；但是，对象和元组字段被视为单独的实体：

  ```nim
  proc consume(x: sink Obj) = discard "no implementation"

  proc main =
    let tup = (Obj(), Obj())
    consume tup[0]
    # ok, only tup[0] was consumed, tup[1] is still alive:
    echo tup[1]
  ```

有时需要将值显式  `move` 到最终位置：  

  ```nim
  proc main =
    var dest, src: array[10, string]
    # ...
    for i in 0..high(dest): dest[i] = move(src[i])
  ```

允许实现，但不需要实现更多的移动优化（当前的实现不需要）。





 Sink 槽参数推理
========================

当前的实现可以进行有限形式的 Sink 参数推断。但它必须通过`--sinkInference:on`启用，无论是在命令行上还是通过  `push` 编译指示启用。

要为一段代码启用它，可以使用 `{.push sinkInference: on.}` 代码段... `{.pop.}`。

`.nosinks` 编译指示可用于禁用为单个例程的参数推断：


  ```nim
  proc addX(x: T; child: T) {.nosinks.} =
    x.s.add child
  ```

推理算法的详细信息目前还没有写文档。




重写规则
=============

**注意**: 有两种不同的允许实现策略：

1.生成的 `finally` 部分可以是包裹在整个例程主体周围的单个部分。
2.生成的 `finally` 部分环绕在封闭范围内。

目前的实施遵循策略（2）。这意味着资源在作用域出口处被销毁。

    var x: T; stmts
    ---------------             (destroy-var)
    var x: T; try stmts
    finally: `=destroy`(x)


    g(f(...))
    ------------------------    (nested-function-call)
    g(let tmp;
    bitwiseCopy tmp, f(...);
    tmp)
    finally: `=destroy`(tmp)


    x = f(...)
    ------------------------    (function-sink)
    `=sink`(x, f(...))


    x = lastReadOf z
    ------------------          (move-optimization)
    `=sink`(x, z)
    wasMoved(z)


    v = v
    ------------------   (self-assignment-removal)
    discard "nop"


    x = y
    ------------------          (copy)
    `=copy`(x, y)


    f_sink(g())
    -----------------------     (call-to-sink)
    f_sink(g())


    f_sink(notLastReadOf y)
    --------------------------     (copy-to-sink)
    (let tmp; `=copy`(tmp, y);
    f_sink(tmp))


    f_sink(lastReadOf y)
    -----------------------     (move-to-sink)
    f_sink(y)
    wasMoved(y)




类和数组构造
=============================
对象和数组构造被视为函数调用，其中函数具有 `sink` 参数。

析构函数删除
==================
`wasMoved(x);` 后跟着执行 `=destroy(x)` ，操作相互抵消。鼓励实现利用这一点，以提高效率和代码大小。当前实现确实执行此优化。




自我复制
================

`=sink` 与 `wasMoved` 结合使用可以处理自我复制，但它很微妙。

 `x=x` 的简单情况不能转换 `=sink(x, x); wasMoved(x)`，因为这将失去`x`的值。解决方案是简单的自我复制，包括
- 符号：`x=x`
- 字段访问：`x.f=x.f`
- 使用编译时已知的索引进行数组、序列或字符串访问：`x[0]=x[0]`。

被转换为一个空的语句，使用都不做。编译器可以自由优化更多的情况。

这个复杂的情况看起来像 `x = f(x)` 的变体，我们这里考虑
`x = select(rand() < 0.5, x, y)` ：



 ```nim
  proc select(cond: bool; a, b: sink string): string =
    if cond:
      result = a # moves a into result
    else:
      result = b # moves b into result

  proc main =
    var x = "abc"
    var y = "xyz"
    # possible self-assignment:
    x = select(true, x, y)
  ```

转换为：

  ```nim
  proc select(cond: bool; a, b: sink string): string =
    try:
      if cond:
        `=sink`(result, a)
        wasMoved(a)
      else:
        `=sink`(result, b)
        wasMoved(b)
    finally:
      `=destroy`(b)
      `=destroy`(a)

  proc main =
    var
      x: string
      y: string
    try:
      `=sink`(x, "abc")
      `=sink`(y, "xyz")
      `=sink`(x, select(true,
        let blitTmp = x
        wasMoved(x)
        blitTmp,
        let blitTmp = y
        wasMoved(y)
        blitTmp))
      echo [x]
    finally:
      `=destroy`(y)
      `=destroy`(x)
  ```

可以手动验证，这个转换对于自我复制（self-assignments）时正确的。




借用类型 Lent 
=========

`proc p(x: sink T)` 表示过程 `p` 拥有 `x` 的所有权。

为了消除更多的创建/复制<->析构对，可以将过程的返回类型注释为 `lent T` 。这对于 `getter` 访问器非常有用，这些访问器试图将不可变的视图放入容器中。

 `sink` 和 `lent`  的注释允许我们删除大多数（如果不是全部）多余的副本和析构。

`lent T` 类似于 `var T` ，是一个隐藏的指针。编译器保证指针不会超过其原点（不会超过范围）。对于 `lent T` 或 `var T` 类型的表达式，不注入析构函数调用。



  ```nim
  type
    Tree = object
      kids: seq[Tree]

  proc construct(kids: sink seq[Tree]): Tree =
    result = Tree(kids: kids)
    # converted into:
    `=sink`(result.kids, kids); wasMoved(kids)
    `=destroy`(kids)

  proc `[]`*(x: Tree; i: int): lent Tree =
    result = x.kids[i]
    # borrows from 'x', this is transformed into:
    result = addr x.kids[i]
    # This means 'lent' is like 'var T' a hidden pointer.
    # Unlike 'var' this hidden pointer cannot be used to mutate the object.

  iterator children*(t: Tree): lent Tree =
    for x in t.kids: yield x

  proc main =
    # everything turned into moves:
    let t = construct(@[construct(@[]), construct(@[])])
    echo t[0] # accessor does not copy the element!
  ```



`.cursor` 游标编译指示
=================

在 `--mm:arc|orc` 模式下，Nim 的 `ref` 类型通过相同的运行时 `钩子` 实现，因此通过引用计数实现。
这意味着不循环结构能立即释放（`--mm:orc`：附带了一个循环收集器）。

使用 `cursor` 编译指示，可以声明分解循环：

  ```nim
  type
    Node = ref object
      left: Node # owning ref
      right {.cursor.}: Node # non-owning ref
  ```



但请注意，这不是 C++ 的 weak_ptr，这意味着正确的字段不参与引用计数，它是一个未经运行时检查的原始指针。

自动引用计数还有一个缺点，即在迭代链接结构上时会引入开销。`cursor` 编译指示也可以用于避免此开销：


  ```nim
  var it {.cursor.} = listRoot
  while it != nil:
    use(it)
    it = it.next
  ```

事实上， `cursor` 通常会防止对象构造/析构对，因此在其他上下文中也很有用。另一种解决方案是使用原始指针（ `ptr` ），这对 Nim 的进化来说更麻烦，也更危险：以后，编译器可以尝试证明 `cursor` 编译指示是安全的，但对于 `ptr’，编译器必须对可能的问题保持沉默。



游标推断/复制省略
===============================

当前实现还执行 `cursor` 推断。游标推断是复制省略的一种形式。

要了解我们如何以及何时能够做到这一点，请考虑以下问题：在 `dest=src` 中，我们什么时候才能真正实现完整副本？仅当 `dest` 或 `src` 随后发生突变时。如果 `dest` 是易于分析的局部变量。如果 `src` 是从形式参数派生的位置，我们也知道它没有变异！换句话说，我们在编译时进行写分析。

这意味着 `借用` 视图可以自然编写，而无需显式的指针间接寻址：

  ```nim
  proc main(tab: Table[string, string]) =
    let v = tab["key"] # inferred as cursor because 'tab' is not mutated.
    # no copy into 'v', no destruction of 'v'.
    use(v)
    useItAgain(v)
  ```



钩子提升
============

元组类型`(A, B, ...)` 的钩子是通过提升所涉及类型 `A`, `B`, ...  的钩子来生成的元组类型。换句话说，副本 `x = y` 被实现为`x[0] = y[0]; x[1] = y[1]; ...` ， 同样适用于 `=sink` 和 `=destroy` 。

其他基于值的复合类型（如 `object` 和 `array` ）也会相应处理。但是，对于 `object` ，可以重写覆盖编译器生成的钩子。这对于数据结构使用更有效的可选遍历，或者为了避免深度递归是很重要的。



钩子生成
===============

覆盖钩子的能力会导致阶段排序问题：

  ```nim
  type
    Foo[T] = object

  proc main =
    var f: Foo[int]
    # error: destructor for 'f' called here before
    # it was seen in this module.

  proc `=destroy`[T](f: var Foo[T]) =
    discard
  ```

解决方案是在使用前定义``proc `=destroy`[T](f: var Foo[T])`` 。编译器为*战略位置*中的所有类型生成隐式钩子，以便可以可靠地检测到显式提供的 `太迟` 的钩子。这些*战略位置*源自重写规则，如下所示：

- 在构造  `let/var x = ...`  中（ var/let 绑定）钩子是为 `typeof(x)` 生成的。
- 在 `x = ...` （赋值）中为  `typeof(x)` 生成钩子。
- 在 `f(...)` （函数调用）中，为 `typeof(f(...))` 生成钩子。
- 对于每个 sink 参数 `x: sink T`  ，将为 `typeof(x)` 生成钩子。



.nodestroy 不析构编译指示
========================

The experimental `nodestroy`:idx: pragma inhibits hook injections. This can be
used to specialize the object traversal in order to avoid deep recursions:

实验性 `nodestroy` 编译指示抑制钩子注入。这可用于特殊对象遍历，以避免深度递归：

  ```nim
  type Node = ref object
    x, y: int32
    left, right: Node

  type Tree = object
    root: Node

  proc `=destroy`(t: var Tree) {.nodestroy.} =
    # use an explicit stack so that we do not get stack overflows:
    var s: seq[Node] = @[t.root]
    while s.len > 0:
      let x = s.pop
      if x.left != nil: s.add(x.left)
      if x.right != nil: s.add(x.right)
      # free the memory explicit:
      dispose(x)
    # notice how even the destructor for 's' is not called implicitly
    # anymore thanks to .nodestroy, so we have to call it on our own:
    `=destroy`(s)
  ```

从这个例子中可以看出，这个解决方案是不够的，最终应该替换为更好的解决方案。



写入时复制
=============
字符串文本实现为 `写时复制` 。将字符串文本分配给变量时，不会创建文本的副本。
相反，变量只指向文本。文本在指向它的不同变量之间共享。复制操作将延迟到第一次写入。

For example:

  ```nim
  var x = "abc"  # no copy
  var y = x      # no copy
  y[0] = 'h'     # copy
  ```


 `addr x` 的抽象失败，因为地址是否将用于变化是未知的。
`prepareMutation` 需要在取地址操作之前调用。例如：

  ```nim
  var x = "abc"
  var y = x

  prepareMutation(y)
  moveMem(addr y[0], addr x[0], 3)
  assert y == "abc"
  ```

