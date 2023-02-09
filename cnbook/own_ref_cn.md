{==+==}

# A new runtime for Nim

2019-03-26
by Araq

{==+==}

# Nim 的新运行时

2019-03-26  <br>

作者： Araq  <br>

译者：ideages <br>
译文时间：2023.2.8 <br>

{==+==}
{==+==}
In this blog post I explore how the full Nim language can be used without a tracing garbage collector. Since strings and sequences in Nim can also be implemented with destructors the puzzle to solve is what to do with Nim's `ref` pointers and `new` keyword.
{==+==}

在这篇博文中，我探讨了在没有跟踪垃圾收集器（GC）的情况下，使用完整的 Nim 语言。由于 Nim 中的字符串和序列（seq）也可以用析构函数实现，所以要解决的问题是如何使用 Nim 的 `ref` 指针和 `new` 关键字。

{==+==}
{==+==}
So let's talk about Pascal from the '70s. Back then some Pascal implementations lacked its `dispose` statement, Pascal's name for what C calls `free` and C++ calls `delete`. It is not clear to me whether this lack of dispose was an oversight or a deliberate design decision.
{==+==}

让我们来谈谈70年代的 Pascal。当时，一些 Pascal 实现缺少 `dispose` 语句，Pascal中的 `dispose` 是 C 调用 `free` 和 C++ 调用 `delete` 的名称。我不清楚这种缺乏释放语句是疏忽还是故意的设计决定。

{==+==}
{==+==}
However, in Ada `new` is a language keyword and a safe operation, whereas a dispose operation needs to be instantiated explicitly via `Ada.Unchecked_Deallocation`. Allocation is safe, deallocation is unsafe.
{==+==}

然而，在Ada中， `new` 是语言关键字和安全操作，而 `dispose` 操作需要通过 `Ada.Unchecked_Dellocation` 显式实例化。分配是安全的，释放是不安全的。

{==+==}
{==+==}
Obviously these languages longed for a garbage collector to bring them the complete memory safety they were after. 50 years later and not only do commonly used implementations of Ada and Pascal **still** lack a garbage collector, there are new languages like Rust and Swift which have some semi automatic memory management but lack any tracing GC technology. What happened? Hardware advanced to a point where memory management and data type layouts are very important for performance, memory access became much slower compared to the CPU, and heap sizes are now measured in Giga- and Terabytes.
{==+==}

显然，这些语言渴望一个垃圾收集器，带来他们所追求的完整内存安全。50年后，不仅 Ada 和 Pascal 的常用实现**仍然**缺少垃圾收集器，还有 Rust 和 Swift 等新语言，它们有一些半自动内存管理，但缺少任何跟踪 GC 技术。怎么搞的？硬件已发展到目前的程度，内存管理和数据类型布局对性能非常重要，而内存访问速度比 CPU 慢得多，堆大小现在以千兆(G)字节和兆兆(T)字节为单位。

{==+==}
{==+==}
Another problem is that tracing GC algorithms are selfish; they only work well when a lot of information about the potential "root set" is available, this makes interoperability between different garbage collectors (and thus between different programming language implementations) quite challenging.
{==+==}

另一个问题是，跟踪 GC 算法是私有的；只有当有大量关于潜在"root set" 根集的信息可用时，它们才能正常工作，这使得不同垃圾收集器之间（以及不同编程语言实现之间）的互操作性非常具有挑战性。

> 译者注：
> 垃圾收集不是由编译器完成的，而是由运行时系统完成的，运行时系统是与已经编译好的代码连接在一起的一些支持程序。所以称为新运行时。
> Rust 使用了复杂的类型系统，赋值有很多语义，可变性和智能指针，声明和创建> 方式都不同。
> Pascal 使用托管资源概念，仅对指针类 new 和 dispose ，使用了引用计数器。
> Swift 使用了 init 和 deinit 方法，使用 clang 的自动引用计数 ARC(Automatic Reference Counting)分配和释放内存；
> 程序的变量和堆分配的记录构成了一个有向图。每个程序变量都是图中的一个根，所以有根集很多。
> 不同垃圾收集器之间互操作，可能在多个进程或者多个动态库之间存在。

{==+==}
{==+==}
## Reference counting

So tracing is "out", let's have a look at reference counting (RC). RC is incomplete, it cannot deal with cyclic data structures. Every known solution to the dynamic cycle detection/reclamation strategy is some form of tracing:
{==+==}

## 引用计数

因此跟踪出局了，让我们来看看引用计数（RC）。RC 是不完整的，它不能处理循环数据结构。已知的动态循环检测/回收策略里，每个解决方案都是某种形式的跟踪：

{==+==}
{==+==}
"Trial deletion" is a trace of a local subgraph. Unfortunately the subgraph can be as large as the set of live objects.
A "backup" mark and sweep GC is a global tracing algorithm.
One way of looking at this problem is that RC cannot deal with cycles because it too eager, it increments the counters even for back references or any other reference that produces a cycle. And after we break up the cycles manually with weak pointer annotations or similar, we're still left with RC's inherent runtime costs which are very hard to optimize away completely.
{==+==}

- "试删除"是局部子图的跟踪。不幸的是，子图可能与活动对象集一样大。

- "备份"标记和清扫 GC 是一种全局跟踪算法。

这个问题的另一方面是，RC 不能很好处理循环。反向引用或任何其他产生循环的引用，RC 都会过多的增加引用的计数。我们用弱指针指示或类似的方法，手动分解循环引用后，我们仍然需要RC固有的运行时成本，这很难完全优化。

>译注：标记和清扫的垃圾收集
>使用深度优先的办法搜索有向图，可以标记出所有可到达节点。任何未被标记的节点都一定是垃圾，应对回收。通过对所有堆地址进行清扫，查找未被标记的节点，便可以回收垃圾。清扫出来的垃圾可以用一个链表链接在一起。清扫阶段也清除所有标记，以便为下一次收集做准备。

>译注：引用计数，通过记住每个记录（有向图中的分配记录）有多少指针指向它，就可以找到具体可达到的记录，可以来简单的识别垃圾。引用计数简单而又吸引力，却存在作者所说的两个主要问题：循环引用和代价巨大。代价是每个指令可能都需要计数器的增减。

{==+==}
{==+==}
Nim's default GC is a deferred reference counting GC. That means that stack slot updates do not cause RC operations. Only pointers on the heap are counted. Since Nim uses thread local heaps the increments and decrements are not atomic. As an experiment I replaced them with atomic operations. The goal was to estimate the costs of atomic reference counting. The result was that on my Haswell CPU bootstrapping time for the Nim compiler itself increased from 4.2s to 4.4s, a slowdown of 5%. And there is no contention on these operations as everything is still single threaded. This suggests to me that reference counting should not be the default implementation strategy for Nim's ref and we need to look at other solutions.
{==+==}

当前 Nim 的默认 GC 是延迟引用计数 GC 。这意味着栈的更新（出入栈）不会导致 RC 操作。只需要计算堆上的指针。由于 Nim 使用线程本地堆，所以增加和减少操作不是原子的。作为一个实验，我用原子操作代替了它们。目标是估算原子引用计数的成本。结果是，在我的 Haswell CPU上，Nim 编译器本身的编译时间从4.2秒增加到4.4秒，下降了5%。由于所有操作都是单线程的，因此在这些操作上的时间没有争议。这表明，引用计数不应该是 Nim 引用类型 `ref` 的默认实现策略，我们需要考虑其他解决方案。

{==+==}
{==+==}
## Manual dispose

A GC was added to Nim because back then this seemed like the best solution to ensure memory safety. In the meantime programming language research advanced and there are solutions that can give us memory safety without a GC.
{==+==}


## 手动析构(dispose)

在 Nim 中添加了 GC ，因为在当时这是确保内存安全的最佳解决方案。与此同时，编程语言的研究取得了进展，有些解决方案可以在没有 GC 的情况下为我们提供内存安全。

{==+==}
{==+==}
Rust-like borrowing extensions are not the only mechanism to accomplish this, there are many different solutions to explore.

So let's consider manual dispose calls. Can we have them and memory safety at the same time? Yes! And a couple of experimental programming languages ([Cockoo](http://www.cs.bu.edu/techreports/pdf/2005-006-cuckoo.pdf) and some [dialect of C#](https://www.microsoft.com/en-us/research/wp-content/uploads/2017/03/kedia2017mem.pdf)) implemented this solution. One key insight is that `new/dispose` need to provide a type-safe interface, the memory is served by type-specific memory allocators. That means that the memory used up for type `T` will only be reused for other instances of type `T`.
{==+==}

类似 Rust 的借用扩展并不是实现这一点的唯一机制，还有许多不同的解决方案需要探索。

因此，让我们考虑手动析构调用。我们能同时拥有它们和内存安全吗？对还有一些实验性编程语言（[Ccockoo](http://www.cs.bu.edu/techreports/pdf/2005-006-cuckoo.pdf)和一些[C#方言](https://www.microsoft.com/en-us/research/wp-content/uploads/2017/03/kedia2017mem.pdf))实施了此解决方案。一个关键的见解是， `new/dispose` 需要提供一个类型安全的接口，内存由特定类型的内存分配器提供。这意味着用于类型 `T` 的内存将仅用于类型 `T` 的实例。

>译注：定制接口，特定内存分配器。是两个方面：分配和析构。子类型或类的具体实例，可能要完成分配和析构的接口，且必须要在适当地方调用。

{==+==}
{==+==}
Here is an example that shows what this means in practice:

```nim
type
  Node = ref object
    data: int

var x = Node(data: 3)
let dangling = x
assert dangling.data == 3
dispose(x)
x = Node(data: 4)
assert dangling.data in {3, 4}
```
{==+==}

下面的例子，说明这在实践中意味着什么：

```nim
type
  Node = ref object
    data: int

var x = Node(data: 3)
let dangling = x
assert dangling.data == 3
dispose(x)
x = Node(data: 4)
assert dangling.data in {3, 4}
```

{==+==}
{==+==}
Usually accessing `dangling.data` would be a "use after free" bug but since dispose returns the memory to a type-safe memory pool we know that `x = Node(data: 4)` will allocate memory from the same pool; either by re-using the object that previously had the value 3 (then we know that `dangling.data == 4)` or by creating a fresh object (then we know `dangling.data == 3`).
{==+==}

通常，访问 `danging.data` 是一个"释放后使用"错误，但由于析构将内存返回到类型安全的内存池，我们知道 `x = Node(data: 4)` 将从同一个池分配内存；或者通过重新使用先前具有值 3 的对象（然后我们知道 `hanging.data==4` ），或者通过创建新对象（然后知道 `dangling.data==3` ）。

{==+==}
{==+==}
Type-specific allocation turns every "use after free" bug into a logical bug but no memory corruption can happen. So ... we have already accomplished "memory safety without a GC". It didn't require a borrow checker nor an advanced type system. It is interesting to compare this to an example that uses array indexing instead of pointers:
{==+==}

特定于类型的分配将每个"释放后使用"错误转化为逻辑错误，但不会发生内存损坏。所以我们已经完成了"没有GC的内存安全" 。它不需要借用检查器，也不需要高级类型系统。使用数组索引，而不用指针，比较下有趣的结果：

{==+==}
{==+==}
```nim
type
  Node = object
    data: int

var nodes: array[4, Node]

var x = 1
nodes[x] = Node(data: 3)
let dangling = x
assert nodes[dangling].data == 3
nodes[x] = Node(data: 4)
assert nodes[dangling].data == 4
```


So if the allocator re-uses dispose'd memory as quickly as possible we can reproduce the same results as the array version. However, this mechanism produces different results than the GC version:
{==+==}

```nim
type
  Node = object
    data: int

var nodes: array[4, Node]

var x = 1
nodes[x] = Node(data: 3)
let dangling = x
assert nodes[dangling].data == 3
nodes[x] = Node(data: 4)
assert nodes[dangling].data == 4
```


因此，如果分配器尽可能快地重新使用已处理的内存，我们可以复制与数组版本相同的结果。然而，此机制产生的结果与 GC 版本不同：

{==+==}
{==+==}
```nim
type
  Node = ref object
    data: int

var x = Node(data: 3)
let dangling = x
assert dangling.data == 3
x = Node(data: 4)
# note: the 'dangling' pointer keeps the object alive
# and so the value is still 3:
assert dangling.data == 3

```

The GC transforms the use-after-free bug into hopefully correct behaviour -- or into logical memory leaks as *liveness* is approximated by *reachability*. Programmers are encouraged to not think about memory and resource management, but in my experience thinking a little about these is required for writing robust software.
{==+==}

```nim
type
  Node = ref object
    data: int

var x = Node(data: 3)
let dangling = x
assert dangling.data == 3
x = Node(data: 4)
# note: the 'dangling' pointer keeps the object alive
# and so the value is still 3:
assert dangling.data == 3

```

GC 将释放后使用的 Bug 转化为希望正确的行为，或者转化为逻辑内存泄漏，因为*活跃度*近似于*可达性*。有些人鼓励程序员不考虑内存和资源管理，但根据我的经验，编写健壮的软件需要考虑这些问题。

{==+==}
{==+==}
Philosophy aside, porting code that uses garbage collection over to code that has to use manual dispose calls everywhere which can then produce subtle changes in behaviour is not a good solution. However, we will keep in mind that type-safe memory reuse is all that it takes for memory safety.

This is not "cheating" either, for example https://www.usenix.org/legacy/event/sec10/tech/full_papers/Akritidis.pdf also tries to mitigate memory handling bugs with this idea.
{==+==}

抛开哲学不谈，将使用垃圾收集的代码移植到必须使用手动处理调用的代码上，这可能会导致行为的细微变化，这不是一个好的解决方案。然而，我们将记住，类型安全的内存重用就是内存安全所需要的全部。

例如，这也不是"欺骗",[Cling：一种减轻指针抖动的内存分配器](<https://www.usenix.org/legacy/event/sec10/tech/full_papers/Akritidis.pdf>)也试图用这个想法来减轻内存处理错误。

>Cling：一种减轻指针抖动的内存分配器，它通过检查内存分配例程的调用堆栈来推断运行时分配对象的类型信息。Cling破坏了一大类针对释放后使用漏洞的攻击，特别是那些劫持C++虚拟函数调度机制的攻击，即使对于分配密集型应用程序，其CPU和物理内存开销也很低。

{==+==}
{==+==}
## Owned ref

The pointer has been called the "goto of data structures" and much like "goto" got replaced by "structured control flow" like if and while statements, maybe ref also needs to be split into different types? The "Ownership You Can Count On" paper proposes such a split.
{==+==}

## 拥有者的引用

指针被称为"数据结构的goto" ，很像 `goto` 被 if 和 while 语句等"结构化控制流"所取代，也许 ref 也需要拆分成不同的类型？《你可以信赖的所有权》一书提出了这样的分法。

>译注 您可以信赖的所有权 2006年出版
提出了一种新的内存管理方法，称为别名计数，它结合了基于类型的对象所有权和非拥有（别名）指针对引用的运行时引用计数。引用计数优化通常消除了90%的所有引用计数操作，使程序加快20-40%。

{==+==}
{==+==}
We distinguish between `ref` and `owned` `ref` pointers. Owned pointers cannot be duplicated, they can only be moved so they are very much like C++'s `unique_ptr`. When an owned pointer disappears, the memory it refers to is deallocated. Unowned refs are reference counted. When the owned ref disappears it is checked that no dangling `ref` exists; the reference count must be zero. The reference counting only has to be done for debug builds in order to detect dangling pointers easily and in a deterministic way. In a release build the RC operations can be left out and with a type based allocator we still have memory safety!
{==+==}

我们区分 `ref` 和 `owned ref` 指针。拥有的指针不能复制，只能移动，因此它们非常像C++的 `unique_ptr` 。当拥有的指针消失时，它所引用的内存将被释放。无主引用被计算在内。当拥有的引用消失时，会检查是否存在悬空 `ref` 引用；引用计数必须为零。只需对调试版本进行引用计数，以便以确定性的方式轻松检测悬空指针。在发布版本中，可以省略 RC 操作，使用基于类型的分配器，我们仍然具有内存安全性！

{==+==}
{==+==}
Nim's `new` returns an owned ref, you can pass an owned ref to either an owned ref or to an unowned ref. `owned ref` helps the compiler in figuring out a graph traversal that is free of cycles. The creation of cycles is prevented at compile-time.

Let's look at some examples:

```nim
type
  Node = ref object
    data: int

var x = Node(data: 3) # inferred to be an ``owned ref``
let dangling: Node = x # unowned ref
assert dangling.data == 3
x = Node(data: 4) # destroys x! But x has dangling refs --> abort.
```
{==+==}

Nim 的 `new` 返回一个拥有的引用，您可以将拥有的引用传递给拥有的引用或未拥有的引用。在编译时禁止创建循环。

让我们看个例子：

```nim
type
  Node = ref object
    data: int

var x = Node(data: 3) # inferred to be an ``owned ref``
let dangling: Node = x # unowned ref
assert dangling.data == 3
x = Node(data: 4) # destroys x! But x has dangling refs --> abort.
```

{==+==}
{==+==}
We need to fix this by setting `dangling` to `nil`:

```nim
type
  Node = ref object
    data: int

var x = Node(data: 3) # inferred to be an ``owned ref``
let dangling: Node = x # unowned ref
assert dangling.data == 3
dangling = nil
# reassignment causes the memory of what ``x`` points to to be freed:
x = Node(data: 4)
# accessing 'dangling' here is invalid as it is nil.
# at scope exit the memory of what ``x`` points to is freed
```
{==+==}

我们需要通过将 `dangling` 设置为 `nil` 来解决此问题：

```nim
type
  Node = ref object
    data: int

var x = Node(data: 3) # inferred to be an ``owned ref``
let dangling: Node = x # unowned ref
assert dangling.data == 3
dangling = nil
# reassignment causes the memory of what ``x`` points to to be freed:
x = Node(data: 4)
# accessing 'dangling' here is invalid as it is nil.
# at scope exit the memory of what ``x`` points to is freed
```

{==+==}
{==+==}
While at first sight it looks bad that this is only detected at runtime, I consider this mostly an implementation detail -- static analysis with abstract interpretation will catch on and find most of these problems at compile time. The programmer needs to prove that no dangling refs exist -- justifying the required and explicit assignment of `dangling = nil`.

This is how a doubly linked list looks like under this new model:

```nim
type
  Node*[T] = ref object
    prev*: Node[T]
    next*: owned Node[T]
    value*: T
  
  List*[T] = object
    tail*: Node[T]
    head*: owned Node[T]

proc append[T](list: var List[T]; elem: owned Node[T]) =
  elem.next = nil
  elem.prev = list.tail
  if list.tail != nil:
    assert(list.tail.next == nil)
    list.tail.next = elem
  list.tail = elem
  if list.head == nil: list.head = elem

proc delete[T](list: var List[T]; elem: Node[T]) =
  if elem == list.tail: list.tail = elem.prev
  if elem == list.head: list.head = elem.next
  if elem.next != nil: elem.next.prev = elem.prev
  if elem.prev != nil: elem.prev.next = elem.next
```
{==+==}

虽然乍一看只有在运行时才检测到很糟糕，但我认为这主要是一个实现细节——带有抽象解释的静态分析将在编译时运行并发现大多数这些问题。程序员需要证明不存在悬空引用——证明 `dangling=nil` 的要求和显式赋值是合理的。

在这个新模型下，双向链接列表是这样的：

```nim
type
  Node*[T] = ref object
    prev*: Node[T]
    next*: owned Node[T]
    value*: T
  
  List*[T] = object
    tail*: Node[T]
    head*: owned Node[T]

proc append[T](list: var List[T]; elem: owned Node[T]) =
  elem.next = nil
  elem.prev = list.tail
  if list.tail != nil:
    assert(list.tail.next == nil)
    list.tail.next = elem
  list.tail = elem
  if list.head == nil: list.head = elem

proc delete[T](list: var List[T]; elem: Node[T]) =
  if elem == list.tail: list.tail = elem.prev
  if elem == list.head: list.head = elem.next
  if elem.next != nil: elem.next.prev = elem.prev
  if elem.prev != nil: elem.prev.next = elem.next
```

{==+==}
{==+==}
Nim has closures which are basically (`functionPointer`, `environmentRef`) pairs. So `owned` also applies for closure. This is how callbacks are done:

```nim
type
  Label* = ref object of Widget
  Button* = ref object of Widget
    onclick*: seq[owned proc()] # when the button is deleted so are
                                # its onclick handlers.

proc clicked*(b: Button) =
  for x in b.onclick: x()

proc onclick*(b: Button; handler: owned proc()) =
  onclick.add handler

proc main =
  var label = newLabel() # inferred to be 'owned'
  var b = newButton() # inferred to be 'owned'
  var weakLabel: Label = label # we need to access it in the closure as unowned.
  
  b.onclick proc() =
    # error: cannot capture an owned 'label' as it is consumed in 'createUI'
    label.text = "button was clicked!"
    # this needs to be written as:
    weakLabel.text = "button was clicked!"
  
  createUI(label, b)
```
{==+==}

Nim的闭包基本上是（ `functionPointer`，`environmentRef` ）对。因此， `owned` 也适用于闭包。回调是这样完成的：


```nim
type
  Label* = ref object of Widget
  Button* = ref object of Widget
    onclick*: seq[owned proc()] # when the button is deleted so are
                                # its onclick handlers.

proc clicked*(b: Button) =
  for x in b.onclick: x()

proc onclick*(b: Button; handler: owned proc()) =
  onclick.add handler

proc main =
  var label = newLabel() # inferred to be 'owned'
  var b = newButton() # inferred to be 'owned'
  var weakLabel: Label = label # we need to access it in the closure as unowned.
  
  b.onclick proc() =
    # error: cannot capture an owned 'label' as it is consumed in 'createUI'
    label.text = "button was clicked!"
    # this needs to be written as:
    weakLabel.text = "button was clicked!"
  
  createUI(label, b)
```

{==+==}
{==+==}
This is slightly messier than in today's Nim but we can add some syntactic sugar later like `unowned(label).text = "..."` or add a language rule like "owned refs accessed in a closure are not owned". Notice how the type system prevents us from creating Swift's "retain cycles" at compile-time.
{==+==}

这比现在的 Nim 稍微混乱一些，但我们可以稍后添加一些语法糖，如 `unowned(label).text = "..."`  或添加一个语言规则，如"在闭包中访问的拥有引用不是拥有的"。注意类型系统如何防止我们在编译时创建 Swift 的"保留周期"的。

{==+==}
{==+==}
## Pros and Cons

This model has significant advantages:

- We can effectively use a shared memory heap, safely. Multi threading your code is much easier.
- Deallocation is deterministic and works with custom destructors.
- We can reason about aliasing, two owned refs cannot point to the same location and that's enforced at compile-time. We can even map `owned ref` to C's `restrict`'ed pointers.
- The runtime costs are much lower than C++'s `shared_ptr` or Swift's reference counting.
- The required runtime mechanisms easily map to weird, limited targets like webassembly or GPUs.
- Porting Nim code to take advantage of this alternative runtime amounts to adding the owned keyword to strategic places. The compiler's error messages will guide you.
- Since it doesn't use tracing the runtime is independent of the involved heap sizes. Heaps of terabytes or kilobytes in size make no difference.
- Doubly linked lists, trees and most other graph structures are easily modeled and don't need a borrow checker or other parametrized type system extensions.
{==+==}

## 优点和缺点

此模型具有显著优势：

- 我们可以安全有效地使用共享内存堆。多线程处理代码容易的多。
- 释放是确定性的，适用于自定义析构函数。
- 我们可以推理别名，两个拥有的引用不能指向同一个位置，这是在编译时强制执行的。我们甚至可以将 `owned ref` 映射到 C 的 `restrict` 限制指针。
- 运行时成本远低于 C++ 的 `shared_ptr` 或 Swift 的引用计数。
- 所需的运行时机制很容易映射到奇怪的、有限的目标，如 webassembly 或 GPU。
- 移植 Nim 代码以利用 此替代运行时 相当于将 `owned` 关键字添加到战略位置。编译器的错误消息将指导您。
- 因为它不使用跟踪，所以运行时与所涉及的堆大小无关。TB 或 KB 大小的堆没有区别。
- 双向列表、树和大多数其他图形结构很容易建模，不需要借用检查器或其他参数化类型的系统扩展。

{==+==}
{==+==}
And of course, disadvantages:

- Dangling unowned refs cause a program abort and are not detected statically. However, in the longer run I expect static analysis to catch up and find most problems statically, much like array indexing can be proved correct these days for the important cases.
- You need to port your code and add `owned` annotations.
- `nil` as a possible value for `ref` stays with us as it is required to disarm dangling pointers.
{==+==}

当然，缺点是：

- 悬空的无主引用会导致程序中止，并且不会静态检测到。然而，从长远来看，我希望静态分析能够赶上，并静态地发现大多数问题，就像数组索引在现在可以证明对重要情况下是正确的一样。
- 您需要移植代码并添加 `owned` 注释。
-  `nil` 作为 `ref` 的一个可能值保留在我们身边，因为它需要解除悬空指针。

{==+==}
{==+==}
## Immutability

With ownership becoming part of the type system we can easily envision a rule like "only the owner should be allowed to mutate the object". Note that this rule cannot be universal, for example in  `proc delete[T](list: var List[T]; elem: Node[T])` we need to be able to mutate `elem's` fields and yet we don't own `elem`, the list does.
{==+==}

## 不变性

随着所有权成为类型系统的一部分，我们可以很容易地设想一个规则，比如"只允许所有者改变对象"。注意，这个规则是不能通用的，例如在 `proc delete[T](list: var List[T]; elem: Node[T])`中，我们需要能够改变的 `elem` 字段，但我们不拥有 `elem` ，列表却拥有。

{==+==}
{==+==}
So here is an idea: An `immutable` pragma that can be attached to the object type T and then assigments like `r.field = value` are forbidden for every `r` of type `ref T`, but they are allowed for `r` of type `owned ref T`:

```nim
type
  Node {.immutable.} = ref object
    le, ri: Node
    data: string

proc select(a, b: Node): Node =
  result = if oracle(): a else: b

proc construct(a, b: Node): owned Node =
  result = Node(data: "new", le: a, ri: b)

proc harmless(a, b: Node) =
  var x = construct(a, b)
  # valid: x is an owned ref:
  x.data = "mutated"

proc harmful(a, b: Node) =
  var x = select(a, b)
  # invalid: x is not an owned ref:
  x.data = "mutated"
```

However, since this pragma will not break any code, it can be added later, after we have added the notion of owned pointers to Nim.

Generated: 2020-08-30 07:29:39 UTC
{==+==}


所以这里有一个想法： 一个 `immutable` 不可变编译指示，可以附加到对象类型 T ，然后对 `ref T` 类型的每个 `r` ，禁止像 `r.field=value` 这样的访问，但对 `owned ref T` 的 `r` 允许：


```nim
type
  Node {.immutable.} = ref object
    le, ri: Node
    data: string

proc select(a, b: Node): Node =
  result = if oracle(): a else: b

proc construct(a, b: Node): owned Node =
  result = Node(data: "new", le: a, ri: b)

proc harmless(a, b: Node) =
  var x = construct(a, b)
  # valid: x is an owned ref:
  x.data = "mutated"

proc harmful(a, b: Node) =
  var x = select(a, b)
  # invalid: x is not an owned ref:
  x.data = "mutated"
```

但是，由于这个编译指示不会破坏任何代码，因此在我们向 Nim 添加了拥有指针的概念之后，可以再添加它。

文档生成时间: 2020-08-30 07:29:39 UTC
文档翻译校队：2023-02-09 09:20 UTC+8

{==+==}
{==+==}

