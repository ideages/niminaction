{==+==}
---
title: "A cost model for Nim"
author: Andreas Rumpf (Araq)
excerpt: "This blog post is the beginning of a cost model for the implementation that is available via `Nim devel` aka Nim version 2."
---
{==+==}
---
title: " Nim 的 成本模型"
author: Andreas Rumpf (Araq)
excerpt: "This blog post is the beginning of a cost model for the implementation that is available via `Nim devel` aka Nim version 2."
---

{==+==}


{==+==}


## A cost model for Nim

> It is impossible to design a system so perfect that no one needs to be
> good.
>
> --- T. S. Eliot
{==+==}

## Nim 的成本模型

> 设计一个完美无瑕，无可挑剔系统，是不可能的。
>
>  --- T·S·艾略特（英国诗人1888 - 1965）

{==+==}


{==+==}
This blog post is the beginning of a cost model for the implementation
that is available via "Nim devel" aka Nim version 2.
{==+==}

这篇博文是实施成本模型的开始，代码可通过 `Nim-devel`（即Nim版本2）获得。

{==+==}


{==+==}
This implementation was designed for **embedded, hard real-time systems**. Generally speaking, assuming you have enough RAM (which is about **64 kB**) all of Nim's language features are supported -- including exception handling and heap-based storage. The implementation
of these features also works on bare metal, without an operating system.
{==+==}

此实现是为**嵌入式硬实时系统**设计的。一般来说，假设您有足够的内存（大约为**64kB**），则支持 Nim 的所有语言特性——包括异常处理和基于堆的存储。这些功能的实现也可以在裸机上运行，无需操作系统。

{==+==}


{==+==}
## Heap-based storage

Why the focus on embedded, hard real-time systems? Because when you do
these well you can also do everything else well! The algorithms used are
oblivious to the heap size: Nim's memory management works well with a
64 kB sized heap but also scales to a 16 gigabyte heap, for example.
{==+==}

## 基于堆的存储

为什么关注嵌入式、硬实时系统？因为当你做好这些工作时，你也可以做好其他的事情！所使用的算法不关注堆大小：例如， Nim 的内存管理在 64kB 大小的堆上运行良好，但也可以扩展到 16GB 的堆。

{==+==}


{==+==}
Memory can be shared effectively between threads without copying in Nim
version 2. The complexity of allocation and deallocation is O(1) and
Nim's default allocator is completely lock-free. Fragmentation is low
(average is 15%, and worst case is 25%) as it is based on the
[TLSF](http://www.gii.upv.es/tlsf/) algorithm. The lock-free ideas have
been taken from [mimalloc](https://github.com/microsoft/mimalloc).
{==+==}

在 Nim2 中，可以在线程之间有效地共享内存，而无需复制。分配和释放的复杂性为 O(1)，Nim 的默认分配器是完全无锁的。碎片化程度较低（平均值为15%，最坏情况为25%），因为它基于[TLSF](http://www.gii.upv.es/tlsf/)算法。无锁思想来自[mimalloc](https://github.com/microsoft/mimalloc).

{==+==}


{==+==}
That means that the cost of `new(x)` or `ObjectRef(fields)` is O(1) for
the allocation and O(`sizeof(x[])`) for the required initialization. If
the object constructor initializes every field *explicitly* the
*implicit* initialization step is optimized out.
{==+==}

这意味着  `new(x)`  或 `ObjectRef(fields)` 的成本对于分配为  O(1) ，对于所需的初始化为 O(`sizeof(x[])`) 。如果对象构造函数 *显式* 初始化每个字段，则 *隐式* 初始化步骤将被优化。

{==+==}


{==+==}
The cost of destruction of a subgraph starting at the root `x` is O(N)
where N is the number of nodes in the subgraph. A subgraph of acyclic
data is immediately destroyed when the refcount of its root reaches 0.
{==+==}

从根 `x` 开始的子图的析构成本是 O（N），其中 N 是子图的节点数。非循环数据的子图在其根的引用计数达到0时立即被析构销毁。

{==+==}


{==+==}
Cyclic data is harder to reason about and best avoided. Nevertheless, if
you end up creating cyclic data the system remains "deterministic" and responsive at all times. You can influence the cycle collector via a new API:
{==+==}

循环数据很难推理，最好避免。然而，如果您最终创建了循环数据，则系统始终保持“确定性”和响应性。您可以通过新的 API 调用循环收集器：

{==+==}


{==+==}
``` nim
proc GC_runOrc*()
  ## Forces a cycle collection pass. The runtime depends on your program
  ## but it does not trace acyclic objects.

proc GC_enableOrc*()
  ## Enables the cycle collector subsystem of `--mm:orc`.

proc GC_disableOrc*()
  ## Disables the cycle collector subsystem of `--mm:orc`.
```
{==+==}

``` nim
proc GC_runOrc*()
  ## 强制一次循环收集。运行时取决于程序，但不跟踪非循环对象。

proc GC_enableOrc*()
  ## 启用 `--mm:orc` 的循环收集子系统。

proc GC_disableOrc*()
  ## 禁用 `--mm:orc` 的循环收集子系统。
```

{==+==}


{==+==}
The idea is that you can schedule a cycle collection when it is
"convenient" for your program. In other words when your program is
currently not busy. However, in my experiments with Nim's async event
loop I saw no benefits in doing so. The lesson to take away here is
**"relax, you'll be fine"**.
{==+==}

这样的想法是，你可以在程序 “方便” 的时候安排一次循环收集。就是说，在程序闲时收集。然而，在我对 Nim 异步事件循环的实验中，我发现这样做没有好处。这里要吸取的教训是 **“放松，你会没事的”**。

{==+==}


{==+==}

## Deterministic exception handling

### Subtype checking in O(1)
{==+==}


## 确定性异常处理

### O(1) 中的子类型检查

{==+==}


{==+==}
Starting with version 2 the `of` operator, which is also used implicitly
in the `except E as ex` construct, is finally as fast as it should be:
It's a range check followed by a memory fetch. The cost is O(1).

Nim's exceptions are based on a good old-fashioned type hierarchy that
supports run-time polymorphism. The different exception classes can vary
in size. As such, exceptions are allocated on the heap. However, it is
possible to preallocate them. The standard library does not do this yet
-- pull requests are welcome!
{==+==}

从 Nim2 开始， `of` 运算符（也在 `except E as ex` 构造中隐式使用）的速度终于达到了应有的速度：它是一个范围检查，然后是内存检索。成本为 O(1)。

Nim 的异常基于支持运行时多态性的老式类型层次结构。不同的异常类的大小可能不同。因此，在堆上分配异常。但是，可以预先分配它们。标准库还没有做到这一点 - 欢迎拉取请求帮助我们！

{==+==}


{==+==}


### Goto-based exception handling

When you compile to C code, exception handling is implemented by setting
an internal error flag that is queried after every function call that
can raise. `setjmp` is not used anymore. To improve the
compiler's abilities to reason about which call "can raise", make
wise use of the `.raises: []` annotation. The error path is
intertwined with the success path with the resulting instruction cache
benefits and drawbacks.

The involved costs are about 2-4 machine instructions after a call that
can raise. (There are known ways to optimize this further into one
instruction for the most common architectures.) This overhead is
annoying but at least it is optimized out for tail calls.
{==+==}

### 基于 Goto 的异常处理

当您编译为 C 代码时，异常处理是通过设置一个内部错误标志来实现的，该标志在每次函数调用后，触发异常都会被查询。 `setjmp` 不再使用了。要让编译器准确推理哪个调用 ”可能触发异常“，使用  `.raises: []` 标记。错误路径与成功路径交织在一起，产生了指令缓存的优点和缺点。

所涉及的成本约为一次呼叫后的 2-4 条机器指令。（对于最常见的体系结构，有已知的方法可以将其进一步优化为一条指令。）这一开销很烦人，但至少针对 尾部调用 进行了优化。

{==+==}


{==+==}


### Table-based exception handling

When you compile to C++ code, the C++ implementation of exception
handling is used -- typically it is based on exception handling tables.

{==+==}

### 基于表的异常处理

当您编译为 C++ 代码时，将使用 C++ 的异常处理实现 —— 通常它基于异常处理表。

{==+==}


{==+==}

### Which one is better

It depends on your program which implementation strategy performs
better.

There are rumors that a table-based exception implementation lacks
"predictable" performance and so should not be used for hard real-time
systems. If these rumors are still true then the goto-based exception
handling should be preferred.




{==+==}

### 哪一个方案更好

这取决于您的计划，哪种实施策略执行得更好。

有传言称，基于表的异常实现缺乏 ”可预测” 的性能，因此不应用于硬实时系统。如果这些传言仍然属实，那么应该首选基于 goto 的异常处理。

{==+==}


{==+==}

## Collections and their costs

### Arrays, objects, tuples and sets

These are mapped to linear sections of storage, directly embedded into
the parent collection. That means that if no `ref` or `ptr` indirections
are involved, they are allocated on the stack -- this is nothing new, it
was always true for every Nim version and memory management mode.

The reason why these can be embedded directly is simple: They are of a
fixed size that is known at compile time.

Flexible buffer handling can be done with `openArray` which is a
`(pointer, length)` pair. Both arrays and sequences can be passed to a
parameter that takes an `openArray`.

{==+==}

## 集合及其成本

### 数组、对象、元组和集合

这些映射到存储的线性部分，直接嵌入到父集合中。这意味着如果不涉及 `ref` 或 `ptr` 间接寻址，它们将在堆栈上分配——这不是什么新鲜事，对于每个 Nim 版本和内存管理模式都是如此。

这些可以直接嵌入的原因很简单：它们具有在编译时已知的固定大小。

`openArray` 是一对 `(pointer, length)` 对，可以实现灵活的缓冲区处理。数组和序列都可以传递给采用 `openArray` 的参数。

{==+==}


{==+==}

### Seqs and strings

Seqs and strings are `(len, p)` pairs in which `p` points to a block of memory,
sometimes called "payload". The payload contains information about the
available capacity followed by the elements, which are stored in order
with no further indirections.

Nim does not implement C++'s "small string optimization" (SSO) for
the following reasons:
{==+==}

### 序列和字符串

Seq和字符串是 `(len, p)` 对，其中  `p` 指向内存块，有时称为“有效负载”。有效负载包含有关可用容量的信息，后面跟着元素，这些元素按顺序存储，没有进一步的间接寻址。

Nim 没有实现 C++ 的 “小字符串优化”（SSO），原因如下：

{==+==}


{==+==}
-   Strings and seqs in Nim are binary compatible: `cast`'ing between
    them is supported.
-   SSO makes *moves* slightly slower and Nim is good at moving data
    around rather than copying.
-   SSO makes the performance harder to predict as small strings are
    significantly faster to create than long strings (for which the storage
    needs to be requested from an allocator). SSO also
    implies that the number of memory indirections differs between long
    and short strings.
{==+==}

- Nim 中的字符串和 seq 是二进制兼容的：支持它们之间的 `cast`。
- SSO *移动*速度稍慢，Nim 擅长移动数据而不是复制数据。
- SSO 使性能更难预测，因为小字符串的创建速度明显快于长字符串（需要从分配器请求存储）。 SSO 还意味着长字符串和短字符串之间内存间接寻址的数量不同。


{==+==}


{==+==}
Instead, string *literals* in Nim cause no allocations and can be
shallow copied in an O(1) operation.

If you disagree with this design choice and want to have strings that do
SSO, there are external packages available
([ssostrings](https://github.com/planetis-m/ssostrings),
[shorteststring](https://github.com/metagn/shorteststring)).

{==+==}

相反，Nim 中的字符串 *字面量* 不会导致分配，并且可以在  O(1) 操作中进行浅层复制。
如果您不同意这种设计选择，并且希望有字符串执行 SSO，则可以使用外部包（[sostrings](https://github.com/planetis-m/ssostrings)，[最短字符串](https://github.com/metagn/shorteststring)).

{==+==}


{==+==}

### Hash tables

Most of Nim's standard library collections are based on hashing and
only offer O(1) behavior on the *average* case. Usually this is not good
enough for a hard real-time setting and so these have to be avoided. In
fact, throughout Nim's history people found cases of pathologically bad
performance for these data structures. Instead containers based on
BTrees can be used that offer O(log N) operations for
lookup/insertion/deletion. A possible implementation can be found
[here](https://github.com/nim-lang/fusion/blob/master/src/fusion/btreetables.nim).

{==+==}

### 哈希表

Nim 的大多数标准库集合都是基于哈希的，并且只提供 “平均” 情况下的O（1）行为。通常，这对于硬实时设置来说不够好，因此必须避免这些设置。事实上，在 Nim 的整个历史中，人们发现了这些数据结构上表现不佳的案例。相反，可以使用基于 BTree 的容器，为查找/插入/删除提供 O(log N) 操作。可以在[此处]找到一个可能的实现(https://github.com/nim-ang/fusion/blob/master/src/fusion/btreetables.nim).

{==+==}


{==+==}




## Threads, locks and condition variables

For better or worse, Nim maps threads, locks and condition variables to
the corresponding POSIX (or Windows) APIs and mechanisms. This means
their costs are not under Nim's control. Using an operating system
designed for hard real-time systems is a good idea.

If your domain is not "hard" real-time but "soft" real-time on a
conventional OS, you can "pin" a thread to particular core via
`system.pinToCpu`. This can mitigate the jitter conventional
operating systems can introduce.
{==+==}


## 线程、锁和条件变量

无论好坏，Nim 都将线程、锁和条件变量映射到相应 POSIX（或Windows）API 和机制。这意味着他们的成本不在 Nim 的控制之下。使用专为硬实时系统设计的操作系统是一个好主意。

如果您的域在传统操作系统上不是 “硬” 实时而是 “软” 实时，您可以通过 `system.pinToCpu` 将线程固定 "pin" 到特定内核。这可以减轻传统操作系统可能带来的抖动。


{==+==}


{==+==}





## Other gotchas

When targeting embedded devices there are many platform-specific knobs
and quirks that are beyond the scope of this document. You need to be
aware that Nim's default debug mode is probably too costly so right
away you should use `-d:release` or a combination of switches like
`--stackTrace:off --opt:size --overflowChecks:off --panics:on` not to
mention the selection of your CPU and OS and setting up a C cross
compiler.

Feel free to join [Nim's discord embedded
channel](https://discord.com/channels/371759389889003530/756920870525730947)
and ask for help!

{==+==}


## 其他陷阱

当针对嵌入式设备时，有许多平台特定的问题超出了本文档的范围。您需要注意， Nim 的默认调试模式可能成本太高，因此应立即使用 `-d:release` 或`--stackTrace:off --opt:size --overflowChecks:off --panics:on` 等开关组合，并选择对应的 CPU 和操作系统以及设置 C 交叉编译器。

欢迎加入[Nim 的嵌入频道](https://discord.com/channels/371759389889003530/756920870525730947) 并寻求帮助！

{==+==}


{==+==}



## Conclusion

Nim's new implementation is excellent for embedded devices, but it is
the nature of constrained devices to need specialized solutions like
custom containers. For example, a specialized growable array container
could save memory if it lacks a "capacity" field and uses only a 16
bit integer to track the current length. Custom containers are easy to
create in Nim and they work well together with the builtin constructs
because they speak a common
[protocol](https://nim-lang.org/docs/destructors.html).

How to write an array that can grow at run time without storing the
capacity is left as an exercise for the reader. Happy hacking!


{==+==}

## 结论

Nim的新实现非常适合嵌入式设备，但受限设备的本质是需要定制容器等特定解决方案。如果专用的可增长数组容器缺少 “容量” 字段并且仅使用 16 位整数来跟踪当前长度，那么它可以节省内存。自定义容器很容易在 Nim 中创建，它们与内置结构一起工作很好，因为它们使用通用的析构[协议](https://nim-lang.org/docs/destructors.html).

如何编写一个可以在运行时增长而不存储容量的数组，留给读者一个练习。编码快乐！

{==+==}


{==+==}


## Donating to Nim

Nim is free and open source. Our work and time is not free. Please
consider sponsoring our work!

You can donate via:

- [Open Collective](https://opencollective.com/nim)
- [BountySource](https://salt.bountysource.com/teams/nim)
- [PayPal](https://www.paypal.com/donate/?hosted_button_id=KYXH3BLJBHZTA)
- Bitcoin: 1BXfuKM2uvoD6mbx4g5xM3eQhLzkCK77tJ

If you are a company, we also offer commercial support.
{==+==}

## 向 Nim 捐赠

Nim 是免费的开源软件。我们的工作和时间都不是免费的。请赞助我们的工作！

您可以通过以下方式捐款：
- [开放集体](https://opencollective.com/nim)
- [奖赏来源](https://salt.bountysource.com/teams/nim)
- [PayPal](https://www.paypal.com/donate/?hosted_button_id=KYXH3BLJBHZTA)
- 比特币钱包：1BXfuKM2uvoD6mbx4g5xM3eQhLzkCK77tJ

如果您是一家公司，我们也乐意提供商业支持。

{==+==}

