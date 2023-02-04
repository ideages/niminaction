{==+==}
## Nim without GC

What do ParaSail, "modern" C++ and Rust have in common? They focus on "pointer free programming" (ok, maybe Rust doesn't, but it uses similar mechanisms). In this blog post I am exploring how we can move Nim into this direction. My goals are:

- Memory safety without GC.
- Make passing data between threads more efficient.
- Make it more natural to write code with excellent performance.
- A simpler programming model: Pointers introduce aliasing, this means programs are hard to reason about, this affects optimizers as well as programmers.
{==+==}

## 没有 GC 的 Nim

原文地址：https://nim-lang.org/araq/destructors.html
作者：Araq
译者：ideages
摘要：新的运行时，无GC情况下，编译器自动析构的解决方案

ParaSail 、现代的 C++ 和 Rust 有什么共同点？他们专注于 `无指针编程` （好吧，也许Rust没有，但它使用了类似的机制）。在这篇博文中，我探讨了如何将 Nim 推向这个方向。我的目标是：

- 无 GC 的内存安全。
- 线程之间的数据传递更加高效。
- 编写性能优异的代码更自然。
- 一个更简单的编程模型：指针引入了别名，这意味着程序很难推理，这影响了优化器和程序员。

> ParaSail 是一种新的并行编程语言 http://adacore.github.io/ParaSail/

{==+==}

{==+==}
The title gave it away: We are going to get into this state of programming Valhalla by eliminating pointers. Of course for low level programming Nim's `ptr` type is here to stay but I hope to avoid `ref` as far as reasonable in the standard library. (`ref` might become an atomic RC'ed pointer.) As a nice side-effect, `nil` ceases to be a problem too. Instead of `ref object` we will use `object` more, this implies the `var` vs "no var" distinction will be used more often, another benefit in my opinion.
{==+==}

标题透露了这一点：我们将通过消除指针，进入到编程的英灵殿。当然，对于底层编程来说，Nim 的 `ptr` 指针类型将继续存在，但我希望在标准库中尽量避免 `ref` 。（ `ref` 可能会变成一个原子的引用计数指针。）另一个好的作用， `nil` 也不再是问题。我们将更多地使用 `object` 而不是 `ref object` ，这意味着 `var` 与 非`var` 的区别将更频繁地使用，这在我看来是另一个好处。

{==+==}

{==+==}
### What's wrong with Nim's GC?

Not much per se (hey, it's likely faster than the alternatives that I'm exploring here) but it makes interoperability with most of what's outside of Nim's ecosystem harder:

- Python has its own GC and while building a Nim DLL that Python can load works, it would be even easier if the DLL wouldn't need special code that ensures the GC's conservative stack scanning works.
- C++ game engines are based on RAII and wrapping a C++ object in a Nim ref object that calls a C++ destructor in a GC finalizer adds overhead. This applies to almost every big C or C++ project.
- The conservative stack scanning can fail for more unusual targets like Emscripten. (Workarounds exist though.)
- I have spent far more time now in fixing GC related bugs or optimizing the GC than I ever spent in hunting down memory leaks or corruptions. Memory safety is not negotiable but we should attempt to get it without a runtime that grows ever more complex. 
{==+==}

### Nim 的 GC 有什么错吗？

本身并没有太多问题（这可能比我在这里探索的替代方案更快），主要是 GC 会使 Nim 与其生态系统之外的互操作性变的困难：

- Python 有自己的 GC ，Nim 很容易创建 Python 用的动态库，但如果在动态库中，去掉 Nim GC 的保守堆栈扫描代码，则会更容易些。

- C++ 游戏引擎基于 RAII ，并将 C++ 对象包装在 Nim ref 对象中，该对象在 GC 结束中调用 C++ 析构函数，从而增加了开销。这几乎适用于所有大型 C 或 C++ 项目。

- 对于像 Emscripten 这样的更不寻常的目标，的保守堆栈扫描可能会失败。（尽管存在变通办法。）

- 我现在花在修复 GC 相关的错误或优化GC上的时间，比我在查找内存泄漏或损坏上花费的时间多得多。内存安全是不可妥协的，应该在运行时变得越来越复杂的情况下实现它。

>Emscripten 是一个开源的编译器 ，该编译器可以将 C/C++ 的代码编译成 JavaScript 胶水代码。 Emscripten 可以将 C/C++ 代码编译为 WebAssembly。

{==+==}

{==+==}
### Containers

Nim's containers should be value types. Explicit move semantics as well as a special optimizer will eliminate most copies.

Almost all containers keep the number of elements they hold and so instead of `nil` we get a much nicer state `len == 0` that is not as prone to crashes as `nil`. When a container is moved, its length becomes 0.

### Slicing

Strings and seqs will support O(1) slicing, other containers might also produce a "view" into their interiors. Slices break up the clear ownership semantics that we're after and so will probably be restricted to parameters much like `openArray`.
{==+==}

### 容器类型

 Nim 的容器应该是值类型。显式移动语义以及特殊的优化器将消除大多数复制。

几乎所有的容器都持有保存的元素数量，因此我们得到了一个更好的状态 `len==0` ，而不是 `nil` ，它不像 `nil` 那样容易崩溃。移动容器时，其长度变为0。

### 切片

字符串和 seq 将支持 O(1) 切片，其他容器也能会生成其内部的"视图" 。切片打破了我们所追求的清晰的所有权语义，因此很可能只限于像 `openArray` 这样的参数。

{==+==}

{==+==}
### Opt
Trees do not require pointers to be constructed, a `seq` can do the same:

```nim
type
  Node = object  ## note the absence of ``ref`` here
    children: seq[Node]
    payload: string
```


However often only 1 or 0 entries are possible and so a `seq` would be overkill. `opt` is a container that can be full or empty, just like the well known Option type from other languages.
{==+==}

### 选项

树不需要构造指针，seq 也可以这样做：

```nim
type
  Node = object  ## note the absence of ``ref`` here
    children: seq[Node]
    payload: string
```

然而，通常只有1或0个条目是可能的，因此 `seq` 会被过度使用，`opt`是一个可以是满的或空的容器，就像其他语言( Scala, CSharp )中众所周知的 Option 类型一样。

{==+==}

{==+==}
```nim
type
  Node = object  ## note the absence of ``ref`` here
    left, right: opt[Node]
    payload: string
```

Under the hood `opt[Note]` uses a pointer, it has to, otherwise a construct like the above would take up an infinite amount of memory ("a node contains nodes which contain nodes which ..."). But since this pointer is not exposed, it doesn't destroy the value semantics. It can be argued that `opt[T]` is very much a unique pointer that adheres to the copy vs move distinction.
{==+==}
```nim
type
  Node = object  ## note the absence of ``ref`` here
    left, right: opt[Node]
    payload: string
```

在 `opt[Note]` 的情况下，它必须使用一个指针，否则像上面这样的构造将占用无限量的内存（ 一个节点包含包含了更多的节点的节点 ）。但是由于这个指针没有公开，它不会破坏值语义。可以说， `opt[T]` 在很大程度上是一个独特的指针，它坚持复制与移动的区别。

{==+==}

{==+==}
### Destructors, assignment and moves

The existing Nim supports moving via `shallowCopy`, this is a bit ugly so from now on a move shall be written as `<-`. Note that `<-` is not a real new operator here, I used it only to emphasize in the examples where a move occurs.

Value semantics make it easy to determine the lifetime of an object, when it goes out of scope, its attached resources can be freed, that means its destructor is called. If it was moved (if it escapes) instead, some internal state in the object or container reflects this and the destruction can be prevented. An optimization pass is allowed to remove destructor calls, likewise a copy propagation pass is allowed to remove assignments.

There are in fact two places where destruction can occur: At scope exit and at assignment, `x = y` means `"destroy x; copy y into x"`. This is often inefficient:
{==+==}

### 析构、分配和移动

现有的 Nim 支持通过"浅拷贝"进行移动，这有点难看，因此从现在开始，移动应写为 `<-` 。注意， `<-` 在这里不是一个真正的新运算符，我使用它只是为了强调在发生移动。

值语义使确定对象的生存期变得容易，当对象超出范围时，可以释放其附加的资源，这意味着调用了其析构函数。如果它被移动（如果它逃逸），物体或容器中的某些内部状态反映了这一点，可以防止破坏。允许优化传递删除析构函数调用，同样允许复制传播传递删除赋值。

事实上，有两个地方可能发生析构：在作用域退出和赋值时， `x=y` 表示 `析构x；将y复制到x` 。这通常是低效的：

{==+==}

{==+==}
```nim
proc put(t: var Table; key, val: string) =
  # outline of a hash table implementation:
  let h = hash(key)
  # these are destructive assignments:
  t.a[h].key = key
  t.a[h].val = val

proc main =
  let key <- stdin.readLine()
  let val <- stdin.readLine()
  var t = createTable()
  t.put key, val
```  

This constructs 2 strings via the `readLine` calls that are then copied into the table `t`. At the scope exit of main the original strings key and val are freed.

This naive code does 2 copies and 4 destructions. We can do much better with `swap`:

```nim
proc put(t: var Table; key, val: var string) =
  # outline of a hash table implementation:
  let h = hash(key)
  swap t.a[h].key, key
  swap t.a[h].val, val

proc main =
  var key <- stdin.readLine()
  var val <- stdin.readLine()
  var t = createTable()
  t.put key, val
```
{==+==}

```nim
proc put(t: var Table; key, val: string) =
  # outline of a hash table implementation:
  let h = hash(key)
  # these are destructive assignments:
  t.a[h].key = key
  t.a[h].val = val

proc main =
  let key <- stdin.readLine()
  let val <- stdin.readLine()
  var t = createTable()
  t.put key, val
```  

这将通过 `readLine` 调用构造2个字符串，然后将其复制到表 `t` 中。在 main 的作用域出口处，原始字符串 key 和 val 被释放。

这个简单的代码做了2次复制和4次析构。我们可以用 `swap` 做得更好：


```nim
proc put(t: var Table; key, val: var string) =
  # outline of a hash table implementation:
  let h = hash(key)
  swap t.a[h].key, key
  swap t.a[h].val, val

proc main =
  var key <- stdin.readLine()
  var val <- stdin.readLine()
  var t = createTable()
  t.put key, val
```

{==+==}

{==+==}
This code now only does the required minimum of 2 destructions. It also quite ugly, `key` and `val` are forced to be `var`'s and after the move into the table `t` they can be accessed and contain the old table entries. This can occasionally be useful but more often we would like to keep the `let` and instead accessing the value after it was moved should produce a compile-time error.

This is made possible by `sink` parameters. A `sink` parameter is like a `var` parameter but `let` variables can be passed to it and afterwards a simple control flow analysis prohibits accesses to the location. With `sink` the example looks as follows:
{==+==}

此代码现在只执行所需的最少2次析构。它也很难看， `key` 和 `val` 被强制为 `var` ，在移动到表 `t` 之后，它们可以被访问并包含旧表条目。这有时会很有用，但更常见的情况是，我们希望保留 `let` ，而在移动值后访问该值会产生编译时错误。

这可以通过 `sink` 参数实现。 `sink` 参数类似于 `var` 参数，但 `let` 变量可以传递给它，然后简单的控制流分析禁止访问该位置。对于 `sink` ，示例如下：

{==+==}

{==+==}
```nim 
proc put(t: var Table; key, val: sink string) =
  # outline of a hash table implementation:
  let h = hash(key)
  swap t.a[h].key, key
  swap t.a[h].val, val

proc main =
  let key <- stdin.readLine()
  let val <- stdin.readLine()
  var t = createTable()
  t.put key, val
```  
{==+==}

```nim 
proc put(t: var Table; key, val: sink string) =
  # outline of a hash table implementation:
  let h = hash(key)
  swap t.a[h].key, key
  swap t.a[h].val, val

proc main =
  let key <- stdin.readLine()
  let val <- stdin.readLine()
  var t = createTable()
  t.put key, val
```  

{==+==}

{==+==}
Alternatively we can simply allow to pass a `let` to a `var` parameter and then it means it's moved.

Btw `let key = stdin.readLine()` will always be transformed into `let key <- stdin.readLine()`.

### Optimizing copies into moves

Consider this example:
{==+==}

或者，我们可以简单地允许将 `let` 传递给 `var` 参数，然后这意味着它被移动了。

`let key = stdin.readLine()` 将始终转换为  `let key <- stdin.readLine()`。

### 将拷贝优化为移动

看看以下示例：

{==+==}

{==+==}
```nim
let key = stdin.readLine()
var a: array[10, string]
a[0] = key
echo key
```

Since `key` is accessed after the assignment `a[0] = key` it has to be copied into the array slot. But without the `echo` key statement the value can be moved. And so that's what the compiler does for us. Blurring the distinction between moves and copies means that code can evolve without "friction".
{==+==}

```nim
let key = stdin.readLine()
var a: array[10, string]
a[0] = key
echo key
```
由于 `key` 在赋值 `a[0]=key` 之后被访问，因此必须将其复制到数组中。但如果没有 `echo key` 语句，则可以移动值。这就是编译器为我们所做的。模糊移动和复制之间的区别意味着代码可以在没有 `摩擦` 的情况下进化。

{==+==}

{==+==}
### Destructors

Every construction needs to be paired with a destruction in order to prevent memory leaks. It also must be destroyed exactly once in order to prevent corruptions. The secret to get memory safety from this model lies in the fact that calls to destructors are always inserted by the compiler.

But what is a construction? Nim has no traditional constructors. The answer is that the `result` of every proc counts as construction. This is no big loss as return values tend to be bad for high performance code. More on this later.
{==+==}

### 析构

为了防止内存泄漏，每个构造都需要与析构配对。为了防止损坏，它也必须被析构一次。从这个模型中获得内存安全的秘诀在于，对析构函数的调用总是由编译器插入。

但什么是构造？ Nim 没有传统的构造函数。答案是，每个过程的 `结果` 都算作构造。这并不是很大的损失，因为返回值对于高性能代码来说往往是不利的。稍后再详细介绍。

{==+==}

{==+==}
### Code generation for destructors

Naive destructors for trees are recursive. This means they can lead to stack overflows and can lead to missed deadlines in a realtime setting. The default code generation for them thus uses an explicit stack that interacts with the memory allocator to implement lazy freeing. Or maybe we can introduce a `lazyDestroy` proc that should be used in strategic places. The implementation could look like this:
{==+==}

### 析构函数的代码生成

树的朴素析构函数是递归的。这意味着它们可能导致堆栈溢出，并可能导致在实时设置中错过最后期限。因此，它们的默认代码生成，使用与内存分配器交互的显式堆栈来实现延迟释放。或者我们可以引入一个 `lazyDestroy` 程序，该程序应该在战略位置使用。实现可能如下所示：

{==+==}

{==+==}
```nim
type Destructor = proc (data: pointer) {.nimcall.}

var toDestroy {.threadvar.}: seq[(Destructor, pointer)]

proc lazyDestroy(arg: pointer; destructor: Destructor) =
  if toDestroy.len >= 100:
    # too many pending destructor calls, run immediately:
    destructor(arg)
  else:
    toDestroy.add((destructor, arg))

proc `=destroy`(x: var T) =
  lazyDestroy cast[pointer](x), proc (p: pointer) =
    let x = cast[var T](p)
    `=destroy`(x.le)
    `=destroy`(x.ri)
    dealloc(p)

proc constructT(): T =
  if toDestroy.len > 0:
    let (d, p) = toDestroy.pop()
    d(p)
```  

This is really just a variant of "object pooling".
{==+==}
```nim
type Destructor = proc (data: pointer) {.nimcall.}

var toDestroy {.threadvar.}: seq[(Destructor, pointer)]

proc lazyDestroy(arg: pointer; destructor: Destructor) =
  if toDestroy.len >= 100:
    # too many pending destructor calls, run immediately:
    destructor(arg)
  else:
    toDestroy.add((destructor, arg))

proc `=destroy`(x: var T) =
  lazyDestroy cast[pointer](x), proc (p: pointer) =
    let x = cast[var T](p)
    `=destroy`(x.le)
    `=destroy`(x.ri)
    dealloc(p)

proc constructT(): T =
  if toDestroy.len > 0:
    let (d, p) = toDestroy.pop()
    d(p)
```  

这实际上只是"对象池"的一种变体。


{==+==}

{==+==}
### Move rules

Now that we have gained these insights, we can finally write down the precise rules when copies, moves and destroys happen:

| Rule |	Pattern |	Meaning |
|------|----------|---------|
| 1 |	var x; stmts	|var x; try stmts finally: destroy(x)|
| 2 |	x = f()	| move(x, f())|
| 3 |	x = lastReadOf z |	move(x, z)|
| 4	|x = y	| copy(x, y) |
| 5	|f(g())	|f((move(tmp, g()); tmp)); destroy(tmp) |
{==+==}

### 移动规则

根据已经获得的这些信息，我们终于可以写下复制、移动和析构发生时的精确规则：

| 规则 |	模式 |	意义 |
|------|----------|---------|
| 1 |	var x; stmts	|var x; try stmts finally: destroy(x)|
| 2 |	x = f()	| move(x, f())|
| 3 |	x = lastReadOf z |	move(x, z)|
| 4	|x = y	| copy(x, y) |
| 5	|f(g())	|f((move(tmp, g()); tmp)); destroy(tmp) |

{==+==}

{==+==}
`var x = y` is handled as `var x; x = y. x, y` here are arbitrary locations, `f` and `g` are routines that take an arbitrary number of arguments, `z` a local variable.

In the current implementation `lastReadOf z` is approximated by "z is read and written only once and that is done in the same basic block". Later versions of the Nim compiler will detect this case more precisely.
{==+==}

`var x=y’被处理为‘var x; x=y ` 。
x，y是任意位置，f和g是接受任意数量参数的例程，z是局部变量。

在当前实现中， `lastReadOf z` 近似为 `z仅读写一次，且在同一基本块中完成` 。

Nim编译器的后续版本将更精确地检测这种情况。

{==+==}

{==+==}
The key insight here is that assignments are resolved into several distinct semantics that do "the right thing". Containers should thus be written to leverage the builtin assignment!

To see what this means, let's look at C++: In C++ there is a distinction between moves and copies and this distinction bubbles up in the APIs, for example `std::vector` has
{==+==}

这里的关键观点是，赋值被分解为几个不同的语义，这些语义做"正确的事情" 。因此，应该编写容器以利用内置赋值！

要了解这意味着什么，让我们看看 C++：在 C++ 中，移动和复制之间有区别，这种区别在 API 中出现，例如 `std:：vector` 有

{==+==}

{==+==}
```c++
void push_back(const value_type& x); // copies the element
void push_back(value_type&& x); // moves the element
```

In Nim we can do better thanks to its `template` feature (which has nothing to do with C++'s templates):
{==+==}

```c++
void push_back(const value_type& x); // copies the element
void push_back(value_type&& x); // moves the element
```

在Nim中，因为有 `template` 模板（与C++的模板无关），我们可以做得更好：

{==+==}

{==+==}
```nim
proc reserveSlot(x: var seq[T]): ptr T =
  if x.len >= x.cap: resize(x)
  result = addr(x.data[x.len])
  inc x.len

template add*[T](x: var seq[T]; y: T) =
  reserveSlot(x)[] = y
```  

Thanks to `add` being a template the final assignment is not hidden from the compiler and so it is allowed to use the most effective form. The implementation uses the unsafe `ptr` and `addr` constructs, but it is generally accepted now that a language's core containers are allowed to do that.
{==+==}

```nim
proc reserveSlot(x: var seq[T]): ptr T =
  if x.len >= x.cap: resize(x)
  result = addr(x.data[x.len])
  inc x.len

template add*[T](x: var seq[T]; y: T) =
  reserveSlot(x)[] = y
```  

由于 `add` 是一个模板，所以编译器不会隐藏最终赋值，因此允许它使用最有效的形式。实现使用不安全的 `ptr` 和 `addr` 构造，但现在普遍接受的是允许语言的核心容器这样做。

{==+==}

{==+==}
This way of writing containers works for more complex cases too:

```nim
template put(t: var Table; key, val: string) =
  # ensure 'key' is evaluated only once:
  let k = key
  
  let h = hash(k)
  t.a[h].key = k    # move (rule 3)
  t.a[h].val = val  # move (rule 3)

proc main =
  var key = stdin.readLine() # move (rule 2)
  var val = stdin.readLine() # move (rule 2)
  var t = createTable()
  t.put key, val
```  
{==+==}

这种编写容器的方式也适用于更复杂的情况：

```nim
template put(t: var Table; key, val: string) =
  # ensure 'key' is evaluated only once:
  let k = key
  
  let h = hash(k)
  t.a[h].key = k    # move (rule 3)
  t.a[h].val = val  # move (rule 3)

proc main =
  var key = stdin.readLine() # move (rule 2)
  var val = stdin.readLine() # move (rule 2)
  var t = createTable()
  t.put key, val
```  

{==+==}

{==+==}
Note how rule 3 ensures that` t.a[h].key = k` is transformed into a move since k is never used again afterwards. (Optimizing away the temporary `k` completely is a story for another time.)

Given these new insights, I assume that `sink` parameters are not required at all. Keeps the language simpler.
{==+==}

注意规则3是如何确保 `t.a[h].key=k` 转换为移动的，因为此后不再使用 `k` 。（完全优化掉临时 `k` 是另一个时代的故事。）

鉴于这些新的见解，我假设根本不需要 `sink` 参数。使语言更简单。

{==+==}

{==+==}
### Getters

Templates also help in avoiding copies introduced by getters:

```nim
template get(x: Container): T = x.field

echo get() # no copy, no move
```

If we replace `template get` with `proc get` here rule 5 would apply and produce:

```nim
proc get(x: Container): T =
  copy result, x.field

echo((var tmp; move(tmp, get()); tmp))
destroy(tmp)
```
{==+==}

### 取得属性的过程（Getters）

模板还有助于避免 getter 引入的副本：

```nim
template get(x: Container): T = x.field

echo get() # no copy, no move
```

如果我们将 `template get` 替换为 `proc get` ，规则5将适用并产生：


```nim
proc get(x: Container): T =
  copy result, x.field

echo((var tmp; move(tmp, get()); tmp))
destroy(tmp)
```

{==+==}

{==+==}
### Strings
Here is an outline of how Nim's standard strings can be implemented with this new scheme. The code is reasonable straight-forward, but you always need to keep two things in mind:

- Assignments and copies need to destroy the old destination.
- Self assignments need to work.

```nim
type
  string = object
    len, cap: int
    data: ptr UncheckedArray[char]

proc add*(s: var string; c: char) =
  if s.len >= s.cap: resize(s)
  s.data[s.len] = c

proc `=destroy`*(s: var string) =
  if s.data != nil:
    dealloc(s.data)
    s.data = nil
    s.len = 0
    s.cap = 0

proc `=move`*(a, b: var string) =
  # we hope this is optimized away for not yet alive objects:
  if a.data != nil and a.data != b.data: dealloc(a.data)
  a.len = b.len
  a.cap = b.cap
  a.data = b.data
  # we hope these are optimized away for dead objects:
  b.len = 0
  b.cap = 0
  b.data = nil

proc `=`*(a: var string; b: string) =
  if a.data != nil and a.data != b.data:
    dealloc(a.data)
    a.data = nil
  a.len = b.len
  a.cap = b.cap
  if b.data != nil:
    a.data = alloc(a.cap)
    copyMem(a.data, b.data, a.cap)
```
{==+==}

### 字符串

下面是 Nim 的标准字符串如何用这个新方案实现的概述。代码是合理的，但您始终需要记住两件事：

- 分配和拷贝需要析构旧目标。
- 自我分配需要发挥作用。

```nim
type
  string = object
    len, cap: int
    data: ptr UncheckedArray[char]

proc add*(s: var string; c: char) =
  if s.len >= s.cap: resize(s)
  s.data[s.len] = c

proc `=destroy`*(s: var string) =
  if s.data != nil:
    dealloc(s.data)
    s.data = nil
    s.len = 0
    s.cap = 0

proc `=move`*(a, b: var string) =
  # we hope this is optimized away for not yet alive objects:
  if a.data != nil and a.data != b.data: dealloc(a.data)
  a.len = b.len
  a.cap = b.cap
  a.data = b.data
  # we hope these are optimized away for dead objects:
  b.len = 0
  b.cap = 0
  b.data = nil

proc `=`*(a: var string; b: string) =
  if a.data != nil and a.data != b.data:
    dealloc(a.data)
    a.data = nil
  a.len = b.len
  a.cap = b.cap
  if b.data != nil:
    a.data = alloc(a.cap)
    copyMem(a.data, b.data, a.cap)
```

{==+==}

{==+==}
Unfortunately the signatures do not match, `=move` takes 2 `var` parameters but according to the transformation rules `move(a, f())` or `move(a, lastRead b)` are produced and these are not addressable locations! So we need different type-bound operator called `=sink` that is used instead.
{==+==}

不幸的是，签名不匹配，`=move`采用2个`var`参数，但根据转换规则，生成了`move(a, f())` 或  `move(a, lastRead b)` ，这些都不是可寻址的位置！因此，我们需要使用名为 `=sink` 的不同类型绑定运算符。


{==+==}

{==+==}
```nim
proc `=sink`*(a: var string, b: string) =
  if a.data != nil and a.data != b.data: dealloc(a.data)
  a.len = b.len
  a.cap = b.cap
  a.data = b.data
```  

The compiler only invokes `sink`. `move` is an explicit programmer optimization. Which can usually also be written as `swap` operation.
{==+==}

```nim
proc `=sink`*(a: var string, b: string) =
  if a.data != nil and a.data != b.data: dealloc(a.data)
  a.len = b.len
  a.cap = b.cap
  a.data = b.data
```  

编译器只调用  `sink` ，` move` 是一个明确的程序员优化。通常也可以写成 `swap` 操作。

{==+==}

{==+==}
### Return values are harmful
Nim's stdlib contains the following coding pattern for the `toString $` operator:

```nim
proc helper(x: Node; result: var string) =
  case x.kind
  of strLit: result.add x.strVal
  of intLit: result.add $x.intVal
  of arrayLit:
    result.add "["
    for i in 0 ..< x.len:
      if i > 0: result.add ", "
      helper(x[i], result)
    result.add "]"

proc `$`(x: Node): string =
  result = ""
  helper(x, result)

```  
{==+==}

### 返回值有害

Nim 的 stdlib 包含以下 `toString $` 运算符的编码模式：

```nim
proc helper(x: Node; result: var string) =
  case x.kind
  of strLit: result.add x.strVal
  of intLit: result.add $x.intVal
  of arrayLit:
    result.add "["
    for i in 0 ..< x.len:
      if i > 0: result.add ", "
      helper(x[i], result)
    result.add "]"

proc `$`(x: Node): string =
  result = ""
  helper(x, result)

```  

{==+==}

{==+==}
(The declaration of the `Node` type is left as an excercise for the reader.) The reason for this workaround with the `helper` proc is that it lets us use `result: var string`, a single string buffer we keep appending to. The naive implementation would instead produce much more allocations and concatenations. We gain a lot by constructing (or in this case: appending) the result directly where it will end up.
{==+==}

（ `Node` 类型的声明留给读者作为练习。）使用 `helper` 过程的这种变通方法的原因是，它允许我们使用 `result:var string` ，这是我们一直附加到的一个字符串缓冲区。天真的实现反而会产生更多的分配和连接。我们通过构造（或者在这种情况下：将结果直接附加到结果的结尾）获得了很多。

{==+==}

{==+==}
Now imagine we want to embed this string in a larger context like an HTML page, `helper` is actually the much more useful interface for speed. This answers the old question "should procs operate inplace or return a new value?".

Excessive inplace operations do lead to a code style that is completely statement-based, the dataflow is much harder to see than in the more FP'ish expression-based style. What Nim needs is a transformation from expression based style to statement style. This transformation is really simple, given a proc like:
{==+==}

现在想象一下，我们想要将这个字符串嵌入到一个更大的上下文中，比如HTML页面， `helper` 实际上是一个更有用的界面。这回答了老问题 `procs应该就地操作还是返回新值？` 。
过多的就地操作确实会导致完全基于语句的代码样式，数据流比基于 函数式编程（FP） 表达式的样式更难看到。Nim需要的是从基于表达式的样式到语句样式的转换。这个转换非常简单，给出了如下过程：


{==+==}

{==+==}
`proc p(args; result: var T): void`

A call to it missing the final parameter `p(args)` is rewritten to `(var tmp: T; p(args, tmp); tmp)`. Ideally the compiler would introduce the minimum of required temporaries in nested calls but such an optimization is far away and one can always choose to write the more efficient version directly.
{==+==}

`proc p(args; result: var T): void`

缺少最后参数 `p(args)` 的对它的调用被重写为`(var tmp: T; p(args, tmp); tmp)`。理想情况下，编译器会在嵌套调用中引入最少的所需临时变量，但这样的优化是遥远的，人们总是可以选择直接编写更高效的版本。

{==+==}

{==+==}
### Reification

Second class types or parameter passing modes like `var` or the imagined `sink` have the problem that they cannot be put into an object. This is more severe than it first seems as any kind of threading or tasking system requires a "reification" of the argument list into a task *object* that is then sent to a queue or thread. In fact in the current Nim neither `await` nor `spawn` supports invoking a proc with `var` parameters and even capturing such a parameter in a closure does not work! The current workaround is to use `ptr` for these. Maybe somebody will come up with a better solution.

{==+==}

### 具体化 Reification

第二类的类型或参数传递模式（如 `var` 或想象中的 `sink` ）存在无法放入对象的问题。这比最初看起来更严重，因为任何类型的线程或任务系统都需要将参数列表**具体化**为任务*对象*，然后将其发送到队列或线程。事实上，在当前的Nim中， `await` 和 `spawn` 都不支持使用 `var` 参数调用 `proc` ，甚至在闭包中捕获这样的参数也不起作用！当前的解决方法是使用指针 `ptr` 。也许有人会想出更好的解决方案。


{==+==}
