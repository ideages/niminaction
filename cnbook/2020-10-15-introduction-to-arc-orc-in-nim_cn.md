{==+==}
---
title: "Introduction to ARC/ORC in Nim"
author: Danil Yarantsev (Yardanico)
excerpt: "Nim is advancing towards more efficient 
memory management models. Let's talk about ARC/ORC 
and see how they will change the way memory works in Nim."
---
{==+==}
---
title: " Nim 的 ARC/ORC 简介"
author: Danil Yarantsev (Yardanico)
译文: ideages
excerpt: " Nim 正在向更高效的内存管理模型发展。我们来说说 ARC/ORC ，看看它们将如何改变 Nim 的内存工作方式。"
---
{==+==}

{==+==}
<div class="sidebarblock">
  <div class="content">
    <div class="title">Guest post</div>
    <div class="paragraph">
      This is a guest post by Danil Yarantsev (Yardanico). If you would like to publish articles as a guest author on nim-lang.org then get in touch with us via
      <a href="https://twitter.com/nim_lang">Twitter</a> or <a href="https://nim-lang.org/community.html">otherwise</a>.
    </div>
  </div>
</div>
{==+==}
<div class="sidebarblock">
  <div class="content">
    <div class="title">客座文章</div>
    <div class="paragraph">
      这是 Danil Yarantsev(Yardanico) 的客座文章。如果您想在 nim-lang.org 上以客座作者的身份发表文章，请通过
      <a href="https://twitter.com/nim_lang">Twitter</a> 或 <a href="https://nim-lang.org/community.html">其他</a> 方式与我们联系。
    </div>
  </div>
</div>
{==+==}

{==+==}
## Intro
Let's start with some history: Nim has traditionally been a garbage collected (GC) language.
Most of the standard library relies on the GC to work.
{==+==}
## Nim 的 ARC/ORC 简介
让我们先了解一下历史：传统上 Nim 是一种使用垃圾回收器（GC）的语言。
大多数标准库都依赖于 GC 来工作。
{==+==}

{==+==}
Of course, you can disable the GC and do manual memory management, but then you
lose access to most of the stdlib (which is [quite big by the way](https://nim-lang.org/docs/lib.html)).
{==+==}
当然，您可以禁用 GC ，手动管理内存，但无法使用大部分（ [很大部分](https://nim-lang.org/docs/lib.html)）标准库了。
{==+==}

{==+==}
The default GC in Nim has been `refc` (deferred reference counting with a mark & sweep phase for cycle collection)
for a long time, with other options available, such as `markAndSweep`, `boehm`, and `go`.
{==+==}
很长时间里，Nim 默认用的 GC 策略是 `refc` （延迟引用计数法：分段标记和扫描循环收集），还有其他几个可选策略：如 `markAndSweep` ,  `boehm` , 和 `go` 可用。
{==+==}

{==+==}
But over the last few years there were new ideas for Nim, related to destructors, owned refs (newruntime), and similar:
- [https://nim-lang.org/araq/destructors.html](https://nim-lang.org/araq/destructors.html)
- [https://nim-lang.org/araq/ownedrefs.html](https://nim-lang.org/araq/ownedrefs.html)

Some of these different ideas have emerged into ARC.
{==+==}
但在过去几年中，Nim 有了新的想法，与析构函数、所有权引用（运行时）等相关:
- [https://nim-lang.org/araq/destructors.html](https://nim-lang.org/araq/destructors.html)
- [https://nim-lang.org/araq/ownedrefs.html](https://nim-lang.org/araq/ownedrefs.html)

其中一些想法已经在ARC中实现。
{==+==}


{==+==}
## What is ARC?
At its core ARC is a memory management model based on Automatic Reference Counting
with destructors and move semantics. Some people mistake Nim's ARC for Swift's ARC, but
there is one big difference: ARC in Nim doesn't use atomic RC.
{==+==}
## ARC 是什么
ARC 是一个内存管理策略。 它的核心模型基于 析构和移动语义(move)的自动引用计数。很多人错把 Nim 的 ARC 认为是 Swift 的ARC，但他们有很大的区别：Nim 的 ARC 不是原子的引用计数。
{==+==}

{==+==}
Reference counting is one of the most popular algorithms for freeing unused
resources of the program. The **reference count** for any managed (controlled by the runtime) reference is how many times that reference is used elsewhere.
When that count becomes zero, the reference and all of its underlying data is destroyed.
{==+==}
引用计数是释放程序中弃用资源的最流行算法之一。任何托管（由运行时控制）引用的**引用计数**是该引用在其他地方使用的次数。当该计数变为零时，引用及其所有基础数据都将被释放。
{==+==}

{==+==}
reference is how many times that reference is used elsewhere.
When that count becomes zero, the reference and all of its underlying data is destroyed.
{==+==}
引用被其他地方引用的次数，就是引用的计数。当计数变为零时，引用及其所有基础数据都将被释放。
{==+==}

{==+==}
The main difference between ARC and Nim GCs is that ARC is fully **deterministic** -
the compiler automatically **injects** destructors when it deems that some variable
(a string, sequence, reference, or something else) is no longer needed.
In this sense, it's similar to C++ with its destructors (RAII).
To illustrate, we can use Nim's ``expandArc`` introspection (will be available in Nim 1.4).
{==+==}
ARC 和 Nim 其他的 GC 最主要的不同是：ARC 是完全**确定性**的：当编译器认为某个变量（字符串、序列、引用或其他）不再需要，它会自动**注入**析构函数。
从这个意义上讲，它与C++的析构函数（RAII）相似。
为了说明，我们可以使用 Nim 的 ``expandArc`` 内省（将在 Nim 1.4 中提供）。
{==+==}

{==+==}
Let's consider some simple code:
```nim
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
```
{==+==}
我们看下面简单的代码：
```nim
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
```
{==+==}

{==+==}
And then use Nim's ARC IR on the `main` procedure by running `nim c --gc:arc --expandArc:main example.nim`.
```nim
var mystr
try:
  mystr = readLine(stdin)
  case mystr
  of "hello":
    echo ["Nice to meet you too!"]
  of "bye":
    echo ["Goodbye!"]
    quit(0)
  else:
    discard
finally:
  `=destroy`(mystr)
```
{==+==}
然后在 `main` 程序上生成 Nim 的 ARC IR（中间表示） ，运行 `nim c --gc:arc --expandArc:main example.nim` 。
```nim
var mystr
try:
  mystr = readLine(stdin)
  case mystr
  of "hello":
    echo ["Nice to meet you too!"]
  of "bye":
    echo ["Goodbye!"]
    quit(0)
  else:
    discard
finally:
  `=destroy`(mystr)
```
{==+==}

{==+==}
What we see here is really interesting - the Nim compiler has wrapped the body
of the `main` proc in a `try: finally` statement (the code in `finally` runs even when an exception
is raised in the `try` block) and inserted a `=destroy` call to our `mystr`
(which is initialised at runtime) so that it's destroyed when it is no longer needed (when its lifetime ends).
{==+==}
我们在这里看到的是非常有趣的：Nim 编译器把`main` 函数包装了在一个`try: finally`语句块中（即使 `try` 块语句内发生了异常， `finally` 块内的语句也会运行），并将我们的 `mystr` （在运行时初始化）的 `=destroy` 调用插入，以便在不再需要时（在其生命周期结束时）将其销毁。
{==+==}

{==+==}
This shows one of the main ARC features: **scope-based memory management**.
A scope is a separate region of code in the program.
Scope-based MM means that the compiler will automatically insert destructor calls
for any variables which need a destructor after the scope ends.
{==+==}
这显示了 ARC 的主要功能之一：**基于作用域的内存管理**。作用域是程序中单独的代码区域。基于作用域的内存管理，就是说编译器将自动在作用域内，插入析构函数调用，使变量在作用域结束后析构。
{==+==}

{==+==}
Many Nim constructs introduce new scopes: procs, funcs, converters,
methods, `block` statements and expressions, `for` and `while` loops, etc.
{==+==}
许多 Nim 构造语句引入了新的作用域：过程(proc)、函数(func)、转换函数(converter)、，
方法(method)、`block` 语句和表达式、 `for` 和 `while` 循环等。
{==+==}

{==+==}
ARC also has so-called **hooks** - special procedures that can be defined
for types to override the default compiler behaviour when destroying/moving/copying
the variable. These are particularly useful when you want to make
custom semantics for your types, deal with low-level operations involving pointers, or do FFI.
{==+==}
ARC 也有被称为 **钩子** 的预定义函数，用于变量析构/移动/复制时，重写默认编译器行为。当您想要为类型创建自定义语义、或处理指针的低级操作、或调用外部接口（FFI）时，这些功能尤为有用。
{==+==}

{==+==}
The main advantages of ARC compared to Nim's current `refc` GC are
(including the ones I talked about above):
{==+==}
ARC 与 Nim 当前的 `refc` GC 相比的主要优点是（包括我上面提到的那些）：
{==+==}

{==+==}
- **Scope-based memory management** (destructors are injected after the scope) -
generally reduces RAM usage of the programs and improves performance.
{==+==}
-**基于作用域的内存管理**（在作用域之后注入析构函数）- 通常减少程序的内存使用并提高性能。
{==+==}

{==+==}
- **Move semantics** - the ability of the compiler to statically analyse
the program and convert memory copies into moves where possible.
{==+==}
-**移动语义** - 编译器静态分析的能力，并在可能的情况下将内存复制转换为移动。
{==+==}

{==+==}
- **Shared heap** - different threads have access to the same memory and you don't need to copy variables to pass them between threads - you can instead move them.
See also [an RFC about isolating and sending data between threads](https://github.com/nim-lang/RFCs/issues/244)
{==+==}
- **共享堆** - 不同的线程可以访问相同的内存，您在线程之间不需要复制变量来传递它们，而是移动它们。
请参阅[在线程间隔离和发送数据的 RFC ](https://github.com/nim-lang/RFCs/issues/244)
{==+==}

{==+==}
- **Easier FFI** (`refc` requires each foreign thread to set up the GC
manually, which is not the case with ARC). This also means that ARC is a much better choice for creating Nim libraries to be used from other languages (.dll, .so, [Python extensions](https://github.com/yglukhov/nimpy), etc).)
{==+==}
- **FFI更简单** ( `refc` 需要每个外部线程手动设置GC（ ARC 没有这个问题），在使用 Nim 为其他语言创建扩展库（`.dll` , `.so` ,[Python 扩展](https://github.com/yglukhov/nimpy)），ARC 成为更好选择。)
{==+==}

{==+==}
- Suitable for [**hard realtime**](https://en.wikipedia.org/wiki/Real-time_computing) programming.

- **Copy elision** (cursor inference) reduces copies to simple cursors (aliases) in many cases.
{==+==}
- 适合[**硬实时的**](https://en.wikipedia.org/wiki/Real-time_computing) 要求的程序。

- **复制省略**（游标推断）在许多情况下将复制减少为简单的游标（别名）。
{==+==}

{==+==}
Generally, ARC is an amazing step for programs to become faster, use less memory, and have predictable behaviour.

To enable ARC for your program, all you have to do is compile with the ``--gc:arc`` switch, or add it to your project's config file (`.nims` or `.cfg`).
{==+==}
一般来说，使用 ARC 是惊人的一步：可以让程序变的更快、使用内存更少，并且行为可预测。
要为您的程序启用 ARC ，您只需使用 ``--gc:arc`` 开关，或将其添加到项目的配置文件(`.nims`  或 `.cfg`)中。
{==+==}


{==+==}
## Problem with cycles

But wait! Haven't we forgotten something? ARC is **reference counting**,
and as we all know, RC doesn't deal with *cycles* by itself.
In short, a cycle is when some variables depend on each other in a way that can resemble a cycle.
Let's consider a simple example: we have 3 objects (A, B, C), and each of them references the other, better shown with a diagram:
{==+==}
## 循环的问题
但是等等！我们忘了什么吗？ARC 是**引用计数**，众所周知，引用计数本身并不处理“循环”。简而言之，循环引用是指一些变量以类似于循环的方式相互依赖。
让我们看一个简单的例子：我们有3个对象（A、B、C），每个对象都引用另一个对象，用一个图更好地显示：
{==+==}

{==+==}
<p style="text-align: center;">
  <img width="256" height="256" src="{{ site.baseurl }}/assets/news/images/yardanico-arc/cycle.svg">
</p>
{==+==}
<p style="text-align: center;">
  <img width="256" height="256" src="{{ site.baseurl }}/assets/news/images/yardanico-arc/cycle.svg">
</p>
{==+==}

{==+==}
To find and collect that cycle we need to have a **cycle collector** - a special part of the runtime which finds and removes cycles that are no longer needed in the program.
{==+==}
要查找和收集该循环，我们需要一个**循环收集器** - 这是运行时的一个特殊部分，用于查找和删除程序中不再需要的循环。
{==+==}

{==+==}
In Nim cycle collection has been done by the mark & sweep phase of the `refc` GC, but it's better to use ARC as the foundation to make something better. That brings us to:
{==+==}
在 Nim 循环收集中，`refc` 已经完成了循环的标记和清除，但最好使用 ARC 作为基础，使其变得更好。这让我们想到：
{==+==}

{==+==}
## ORC - Nim's cycle collector
ORC is Nim's all-new cycle collector based on ARC.
It can be considered a full-blown GC since it includes a local tracing phase (contrary to most other tracing GCs which do global tracing).
ORC is what you should use when working with Nim's async because it contains cycles
that need to be dealt with.
{==+==}
## ORC - Nim 循环收集器
ORC是Nim基于ARC的全新循环垃圾收集器。它可以被认为是一个全面的GC，因为它包括一个局部跟踪阶段（与大多数其他进行全局跟踪的跟踪GC相反）。
ORC是使用Nim的异步时应该使用的，因为它包含循环需要处理的问题。
{==+==}

{==+==}
ORC retains most of ARC's advantages
except **determinism** (partially) - by default ORC has an adaptive threshold for collecting cycles, and **hard realtime** (partially), for the same reason.
To enable ORC you need to compile your program with ``--gc:orc``,
but ORC will probably become Nim's default GC in the future.
{==+==}
ORC 保留了 ARC 的大部分优势
除了**确定性**（部分）- 默认情况下，ORC 具有自适应阈值，用于采集周期，以及 **硬实时**（部分），原因相同。
要启用 ORC ，使用 ``--gc:orc`` 编译程序，但 ORC 将来会成为 Nim 的默认GC。
{==+==}


{==+==}
## I'm excited! How do I test them out?
{==+==}
## 我很兴奋！我如何测试它们？
{==+==}

{==+==}
ARC is available in Nim 1.2.x releases, but due to some fixed bugs it's better to
wait for the **Nim 1.4** release (it should be out soon) which will have ARC and ORC available for wide testing.
But if you're eager to try them out, there's a [1.4 release candidate](https://github.com/nim-lang/nightlies/releases/tag/2020-10-07-version-1-4-3b901d1e361f49d48fb64d115e42c04a4a37100c) available.
{==+==}
ARC 在Nim 1.2.x 版本中可用，但由于一些错误的修复，最好等待 **Nim 1.4** 版本（不久就会发布），该版本将提供 ARC 和 ORC 进行广泛测试。
但如果你急于尝试，有一个[1.4版本的RC版本](https://github.com/nim-lang/nightlies/releases/tag/2020-10-07-version-1-4-3b901d1e361f49d48fb64d115e42c04a4a37100c)可用。
{==+==}

{==+==}
That's all! Thank you for reading the article - I hope you enjoyed it and will enjoy the amazing possibilities that ARC/ORC bring to Nim :)
{==+==}
这就是全部！感谢您阅读这篇文章-我希望您喜欢它，并将享受 ARC/ORC 为 Nim 带来的惊人可能性：）
{==+==}

{==+==}
Sources / further information:
- [Introducing --gc:arc](https://forum.nim-lang.org/t/5734)
- [Update on --gc:arc](https://forum.nim-lang.org/t/6549)
- [New garbage collector --gc:orc is a joy to use.](https://forum.nim-lang.org/t/6483)
- [Nim destructors and move semantics](https://nim-lang.org/docs/destructors.html)
- [FOSDEM 2020 - Move semantics for Nim](https://www.youtube.com/watch?v=yA32Wxl59wo)
- [NimConf 2020 - Nim ARC/ORC](https://www.youtube.com/watch?v=aUJcYTnPWCg)
- [Nim community](https://nim-lang.org/community.html)
- [RFC: Unify Nim's GC/memory management options](https://github.com/nim-lang/RFCs/issues/177)
{==+==}
资源/更多信息：
- [--gc:arc简介](https://forum.nim-lang.org/t/5734)
- [--gc:arc更新](https://forum.nim-lang.org/t/6549)
- [新的垃圾收集器--gc:orc使用起来很开心。](https://forum.nim-lang.org/t/6483)
- [Nim析构函数和移动语义](https://nim-lang.org/docs/destructors.html)
- [ FOSDEM 2020-Nim的移动语义](https://www.youtube.com/watch?v=yA32Wxl59wo)
- [ NimConf 2020-Nim ARC/ORC](https://www.youtube.com/watch?v=aUJcYTnPWCg)
- [ Nim 社区](https://nim-lang.org/community.html)
- [ RFC:统一的 Nim GC/内存管理选项](https://github.com/nim-lang/RFCs/issues/177)
{==+==}
