{==+==}

# A new runtime for Nim

2019-03-26
by Araq

{==+==}

# Nim 的新运行时

2019-03-26  

作者： Araq  

译者：ideages
译文时间：2023.2.8

{==+==}
{==+==}
In this blog post I explore how the full Nim language can be used without a tracing garbage collector. Since strings and sequences in Nim can also be implemented with destructors the puzzle to solve is what to do with Nim's `ref` pointers and `new` keyword.
{==+==}

在这篇博文中，我探讨了在没有跟踪垃圾收集器的情况下使用完整的 Nim 语言。由于 Nim 中的字符串和序列（seq）也可以用析构函数实现，所以要解决的问题是如何使用 Nim 的“ref”指针和“new”关键字。

{==+==}
{==+==}
So let's talk about Pascal from the '70s. Back then some Pascal implementations lacked its `dispose` statement, Pascal's name for what C calls `free` and C++ calls `delete`. It is not clear to me whether this lack of dispose was an oversight or a deliberate design decision.
{==+==}

让我们来谈谈70年代的 Pascal。当时，一些 Pascal 实现缺少“dispose”语句，Pascal中的“dispose”是 C 调用“free”和 C++ 调用“delete”的名称。我不清楚这种缺乏释放语句是疏忽还是故意的设计决定。

{==+==}
{==+==}
However, in Ada `new` is a language keyword and a safe operation, whereas a dispose operation needs to be instantiated explicitly via `Ada.Unchecked_Deallocation`. Allocation is safe, deallocation is unsafe.
{==+==}

然而，在Ada中，“new”是语言关键字和安全操作，而 `dispose` 操作需要通过“Ada.Unchecked_Dellocation”显式实例化。分配是安全的，释放是不安全的。

{==+==}
{==+==}
Obviously these languages longed for a garbage collector to bring them the complete memory safety they were after. 50 years later and not only do commonly used implementations of Ada and Pascal **still** lack a garbage collector, there are new languages like Rust and Swift which have some semi automatic memory management but lack any tracing GC technology. What happened? Hardware advanced to a point where memory management and data type layouts are very important for performance, memory access became much slower compared to the CPU, and heap sizes are now measured in Giga- and Terabytes.
{==+==}

显然，这些语言渴望一个垃圾收集器，带来他们所追求的完整内存安全。50年后，不仅 Ada 和 Pascal 的常用实现**仍然**缺少垃圾收集器，还有Rust和Swift等新语言，它们有一些半自动内存管理，但缺少任何跟踪GC技术。怎么搞的？硬件已发展到内存管理和数据类型布局对性能非常重要的程度，内存访问速度比CPU慢得多，堆大小现在以千兆字节和兆字节为单位。

{==+==}
{==+==}
Another problem is that tracing GC algorithms are selfish; they only work well when a lot of information about the potential "root set" is available, this makes interoperability between different garbage collectors (and thus between different programming language implementations) quite challenging.
{==+==}

另一个问题是，跟踪 GC 算法是私有的；只有当有大量关于潜在"root set"根集的信息可用时，它们才能正常工作，这使得不同垃圾收集器之间（以及不同编程语言实现之间）的互操作性非常具有挑战性。

> Rust 使用了复杂的类型系统，赋值有很多语义，可变性和智能指针，声明和创建方式都不同。
Pascal 使用托管资源概念，仅对指针类 new 和 dispose ，使用了引用计数器。
Swift 使用了 init 和 deinit 方法，使用 clang 的自动引用计数 ARC(Automatic Reference Counting)分配和释放内存；

{==+==}
{==+==}
## Reference counting

So tracing is "out", let's have a look at reference counting (RC). RC is incomplete, it cannot deal with cyclic data structures. Every known solution to the dynamic cycle detection/reclamation strategy is some form of tracing:
{==+==}

## 引用计数
所以跟踪是“out”的，让我们来看看引用计数（RC）。RC是不完整的，它不能处理循环数据结构。动态循环检测/回收策略的每个已知解决方案都是某种形式的跟踪：

{==+==}
{==+==}
"Trial deletion" is a trace of a local subgraph. Unfortunately the subgraph can be as large as the set of live objects.
A "backup" mark and sweep GC is a global tracing algorithm.
One way of looking at this problem is that RC cannot deal with cycles because it too eager, it increments the counters even for back references or any other reference that produces a cycle. And after we break up the cycles manually with weak pointer annotations or similar, we're still left with RC's inherent runtime costs which are very hard to optimize away completely.
{==+==}

“试删除”是局部子图的痕迹。不幸的是，子图可能与活动对象集一样大。

“备份”标记和扫描GC是一种全局跟踪算法。

看待这个问题的一种方式是，RC 无法处理循环，因为它太过急切，它会增加计数器，即使是反向引用或任何其他产生循环的引用。在我们用弱指针注释或类似的方法手动分解循环之后，我们仍然会留下 RC 固有的运行时成本，这很难完全优化。

{==+==}
{==+==}
Nim's default GC is a deferred reference counting GC. That means that stack slot updates do not cause RC operations. Only pointers on the heap are counted. Since Nim uses thread local heaps the increments and decrements are not atomic. As an experiment I replaced them with atomic operations. The goal was to estimate the costs of atomic reference counting. The result was that on my Haswell CPU bootstrapping time for the Nim compiler itself increased from 4.2s to 4.4s, a slowdown of 5%. And there is no contention on these operations as everything is still single threaded. This suggests to me that reference counting should not be the default implementation strategy for Nim's ref and we need to look at other solutions.
{==+==}

Nim的默认GC是延迟引用计数GC。这意味着 栈的 更新（出入栈）不会导致 RC 操作。只计算堆上的指针。由于 Nim 使用线程本地堆，所以增量和减量不是原子的。作为一个实验，我用原子操作代替了它们。目标是估算原子参考计数的成本。结果是，在我的Haswell CPU上，Nim 编译器本身的启动时间从4.2秒增加到4.4秒，下降了5%。由于所有操作都是单线程的，因此在这些操作上没有争议。这向我表明，引用计数不应该是 Nim 引用类型 `ref` 的默认实现策略，我们需要考虑其他解决方案。

{==+==}
{==+==}
## Manual dispose

A GC was added to Nim because back then this seemed like the best solution to ensure memory safety. In the meantime programming language research advanced and there are solutions that can give us memory safety without a GC.
{==+==}


## 手动析构(dispose)

在 Nim 中添加了 GC ，因为当时这似乎是确保内存安全的最佳解决方案。与此同时，编程语言的研究取得了进展，有一些解决方案可以在没有 GC 的情况下为我们提供内存安全。

{==+==}
{==+==}
Rust-like borrowing extensions are not the only mechanism to accomplish this, there are many different solutions to explore.

So let's consider manual dispose calls. Can we have them and memory safety at the same time? Yes! And a couple of experimental programming languages ([Cockoo](http://www.cs.bu.edu/techreports/pdf/2005-006-cuckoo.pdf) and some [dialect of C#](https://www.microsoft.com/en-us/research/wp-content/uploads/2017/03/kedia2017mem.pdf)) implemented this solution. One key insight is that `new/dispose` need to provide a type-safe interface, the memory is served by type-specific memory allocators. That means that the memory used up for type `T` will only be reused for other instances of type `T`.
{==+==}

类似 Rust 的借用扩展并不是实现这一点的唯一机制，有许多不同的解决方案需要探索。
因此，让我们考虑手动析构调用。我们能同时拥有它们和内存安全吗？对还有一些实验性编程语言（[Ccockoo](http://www.cs.bu.edu/techreports/pdf/2005-006-cuckoo.pdf)和一些[C#方言](https://www.microsoft.com/en-us/research/wp-content/uploads/2017/03/kedia2017mem.pdf))实施了此解决方案。一个关键的见解是，“new/dispose”需要提供一个类型安全的接口，内存由特定类型的内存分配器提供。这意味着用于类型“T”的内存将仅用于类型“T”的其他实例。

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

通常，访问“danging.data”是一个“释放后使用”错误，但由于析构将内存返回到类型安全的内存池，我们知道 `x = Node(data: 4)` 将从同一个池分配内存；或者通过重新使用先前具有值 3 的对象（然后我们知道“hanging.data==4”），或者通过创建新对象（然后知道“hangg.data==3”）。

{==+==}
{==+==}
Type-specific allocation turns every "use after free" bug into a logical bug but no memory corruption can happen. So ... we have already accomplished "memory safety without a GC". It didn't require a borrow checker nor an advanced type system. It is interesting to compare this to an example that uses array indexing instead of pointers:
{==+==}

特定于类型的分配将每个“释放后使用”错误转化为逻辑错误，但不会发生内存损坏。所以我们已经完成了“没有GC的内存安全”。它不需要借用检查器，也不需要高级类型系统。将其与使用数组索引而不是指针的示例进行比较很有趣：

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

GC将释放后使用的bug转化为希望正确的行为，或者转化为逻辑内存泄漏，因为*活跃度*近似于*可达性*。有些人鼓励程序员不考虑内存和资源管理，但根据我的经验，编写健壮的软件需要考虑这些问题。

{==+==}
{==+==}
Philosophy aside, porting code that uses garbage collection over to code that has to use manual dispose calls everywhere which can then produce subtle changes in behaviour is not a good solution. However, we will keep in mind that type-safe memory reuse is all that it takes for memory safety.

This is not "cheating" either, for example https://www.usenix.org/legacy/event/sec10/tech/full_papers/Akritidis.pdf also tries to mitigate memory handling bugs with this idea.
{==+==}

撇开哲学不谈，将使用垃圾收集的代码移植到必须在任何地方使用手动处理调用的代码上，这可能会导致行为的细微变化，这不是一个好的解决方案。然而，我们将记住，类型安全的内存重用是内存安全所需要的全部。
例如，这也不是“欺骗”https://www.usenix.org/legacy/event/sec10/tech/full_papers/Akritidis.pdf也试图用这个想法来减轻内存处理错误。

{==+==}
{==+==}
## Owned ref

The pointer has been called the "goto of data structures" and much like "goto" got replaced by "structured control flow" like if and while statements, maybe ref also needs to be split into different types? The "Ownership You Can Count On" paper proposes such a split.
{==+==}

## 
指针被称为“数据结构的goto”，很像“goto”被if和while语句等“结构化控制流”所取代，也许ref也需要拆分成不同的类型？《你可以信赖的所有权》一书提出了这样的分割。

{==+==}
{==+==}
We distinguish between `ref` and `owned` `ref` pointers. Owned pointers cannot be duplicated, they can only be moved so they are very much like C++'s `unique_ptr`. When an owned pointer disappears, the memory it refers to is deallocated. Unowned refs are reference counted. When the owned ref disappears it is checked that no dangling `ref` exists; the reference count must be zero. The reference counting only has to be done for debug builds in order to detect dangling pointers easily and in a deterministic way. In a release build the RC operations can be left out and with a type based allocator we still have memory safety!
{==+==}



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



{==+==}
{==+==}
This is slightly messier than in today's Nim but we can add some syntactic sugar later like `unowned(label).text = "..."` or add a language rule like "owned refs accessed in a closure are not owned". Notice how the type system prevents us from creating Swift's "retain cycles" at compile-time.
{==+==}



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



{==+==}
{==+==}
And of course, disadvantages:

- Dangling unowned refs cause a program abort and are not detected statically. However, in the longer run I expect static analysis to catch up and find most problems statically, much like array indexing can be proved correct these days for the important cases.
- You need to port your code and add `owned` annotations.
- `nil` as a possible value for `ref` stays with us as it is required to disarm dangling pointers.
{==+==}



{==+==}
{==+==}
## Immutability

With ownership becoming part of the type system we can easily envision a rule like "only the owner should be allowed to mutate the object". Note that this rule cannot be universal, for example in  `proc delete[T](list: var List[T]; elem: Node[T])` we need to be able to mutate `elem's` fields and yet we don't own `elem`, the list does.
{==+==}



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



{==+==}
{==+==}

