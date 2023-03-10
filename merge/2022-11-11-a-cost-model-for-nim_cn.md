---
title: " Nim 的 成本模型"
author: Andreas Rumpf (Araq)
excerpt: "This blog post is the beginning of a cost model for the implementation that is available via `Nim devel` aka Nim version 2."
---



# Nim 的成本模型

> 设计一个完美无瑕，无可挑剔系统，是不可能的。
>
>  --- T·S·艾略特（英国诗人1888 - 1965）



这篇博文是实施成本模型的开始，代码可通过 `Nim-devel`（即Nim版本2）获得。



此实现是为**嵌入式硬实时系统**设计的。一般来说，假设您有足够的内存（大约为**64kB**），则支持 Nim 的所有语言特性——包括异常处理和基于堆的存储。这些功能的实现也可以在裸机上运行，无需操作系统。



## 基于堆的存储

为什么关注嵌入式、硬实时系统？因为当你做好这些工作时，你也可以做好其他的事情！所使用的算法不关注堆大小：例如， Nim 的内存管理在 64kB 大小的堆上运行良好，但也可以扩展到 16GB 的堆。



在 Nim2 中，可以在线程之间有效地共享内存，而无需复制。分配和释放的复杂性为 O(1)，Nim 的默认分配器是完全无锁的。碎片化程度较低（平均值为15%，最坏情况为25%），因为它基于[TLSF](http://www.gii.upv.es/tlsf/)算法。无锁思想来自[mimalloc](https://github.com/microsoft/mimalloc).



这意味着  `new(x)`  或 `ObjectRef(fields)` 的成本对于分配为  O(1) ，对于所需的初始化为 O(`sizeof(x[])`) 。如果对象构造函数 *显式* 初始化每个字段，则 *隐式* 初始化步骤将被优化。



从根 `x` 开始的子图的析构成本是 O（N），其中 N 是子图的节点数。非循环数据的子图在其根的引用计数达到0时立即被析构销毁。



循环数据很难推理，最好避免。然而，如果您最终创建了循环数据，则系统始终保持“确定性”和响应性。您可以通过新的 API 调用循环收集器：



``` nim
proc GC_runOrc*()
  ## 强制一次循环收集。运行时取决于程序，但不跟踪非循环对象。

proc GC_enableOrc*()
  ## 启用 `--mm:orc` 的循环收集子系统。

proc GC_disableOrc*()
  ## 禁用 `--mm:orc` 的循环收集子系统。
```



这样的想法是，你可以在程序 “方便” 的时候安排一次循环收集。就是说，在程序闲时收集。然而，在我对 Nim 异步事件循环的实验中，我发现这样做没有好处。这里要吸取的教训是 **“放松，你会没事的”**。




## 确定性异常处理

### O(1) 中的子类型检查



从 Nim2 开始， `of` 运算符（也在 `except E as ex` 构造中隐式使用）的速度终于达到了应有的速度：它是一个范围检查，然后是内存检索。成本为 O(1)。

Nim 的异常基于支持运行时多态性的老式类型层次结构。不同的异常类的大小可能不同。因此，在堆上分配异常。但是，可以预先分配它们。标准库还没有做到这一点 - 欢迎拉取请求帮助我们！



### 基于 Goto 的异常处理

当您编译为 C 代码时，异常处理是通过设置一个内部错误标志来实现的，该标志在每次函数调用后，触发异常都会被查询。 `setjmp` 不再使用了。要让编译器准确推理哪个调用 ”可能触发异常“，使用  `.raises: []` 标记。错误路径与成功路径交织在一起，产生了指令缓存的优点和缺点。

所涉及的成本约为一次呼叫后的 2-4 条机器指令。（对于最常见的体系结构，有已知的方法可以将其进一步优化为一条指令。）这一开销很烦人，但至少针对 尾部调用 进行了优化。



### 基于表的异常处理

当您编译为 C++ 代码时，将使用 C++ 的异常处理实现 —— 通常它基于异常处理表。



### 哪一个方案更好

这取决于您的计划，哪种实施策略执行得更好。

有传言称，基于表的异常实现缺乏 ”可预测” 的性能，因此不应用于硬实时系统。如果这些传言仍然属实，那么应该首选基于 goto 的异常处理。



## 集合及其成本

### 数组、对象、元组和集合

这些映射到存储的线性部分，直接嵌入到父集合中。这意味着如果不涉及 `ref` 或 `ptr` 间接寻址，它们将在堆栈上分配——这不是什么新鲜事，对于每个 Nim 版本和内存管理模式都是如此。

这些可以直接嵌入的原因很简单：它们具有在编译时已知的固定大小。

`openArray` 是一对 `(pointer, length)` 对，可以实现灵活的缓冲区处理。数组和序列都可以传递给采用 `openArray` 的参数。



### 序列和字符串

Seq和字符串是 `(len, p)` 对，其中  `p` 指向内存块，有时称为“有效负载”。有效负载包含有关可用容量的信息，后面跟着元素，这些元素按顺序存储，没有进一步的间接寻址。

Nim 没有实现 C++ 的 “小字符串优化”（SSO），原因如下：



- Nim 中的字符串和 seq 是二进制兼容的：支持它们之间的 `cast`。
- SSO *移动*速度稍慢，Nim 擅长移动数据而不是复制数据。
- SSO 使性能更难预测，因为小字符串的创建速度明显快于长字符串（需要从分配器请求存储）。 SSO 还意味着长字符串和短字符串之间内存间接寻址的数量不同。




相反，Nim 中的字符串 *字面量* 不会导致分配，并且可以在  O(1) 操作中进行浅层复制。
如果您不同意这种设计选择，并且希望有字符串执行 SSO，则可以使用外部包（[sostrings](https://github.com/planetis-m/ssostrings)，[最短字符串](https://github.com/metagn/shorteststring)).



### 哈希表

Nim 的大多数标准库集合都是基于哈希的，并且只提供 “平均” 情况下的O（1）行为。通常，这对于硬实时设置来说不够好，因此必须避免这些设置。事实上，在 Nim 的整个历史中，人们发现了这些数据结构上表现不佳的案例。相反，可以使用基于 BTree 的容器，为查找/插入/删除提供 O(log N) 操作。可以在[此处]找到一个可能的实现(https://github.com/nim-ang/fusion/blob/master/src/fusion/btreetables.nim).




## 线程、锁和条件变量

无论好坏，Nim 都将线程、锁和条件变量映射到相应 POSIX（或Windows）API 和机制。这意味着他们的成本不在 Nim 的控制之下。使用专为硬实时系统设计的操作系统是一个好主意。

如果您的域在传统操作系统上不是 “硬” 实时而是 “软” 实时，您可以通过 `system.pinToCpu` 将线程固定 "pin" 到特定内核。这可以减轻传统操作系统可能带来的抖动。





## 其他陷阱

当针对嵌入式设备时，有许多平台特定的问题超出了本文档的范围。您需要注意， Nim 的默认调试模式可能成本太高，因此应立即使用 `-d:release` 或`--stackTrace:off --opt:size --overflowChecks:off --panics:on` 等开关组合，并选择对应的 CPU 和操作系统以及设置 C 交叉编译器。

欢迎加入[Nim 的嵌入频道](https://discord.com/channels/371759389889003530/756920870525730947) 并寻求帮助！



## 结论

Nim的新实现非常适合嵌入式设备，但受限设备的本质是需要定制容器等特定解决方案。如果专用的可增长数组容器缺少 “容量” 字段并且仅使用 16 位整数来跟踪当前长度，那么它可以节省内存。自定义容器很容易在 Nim 中创建，它们与内置结构一起工作很好，因为它们使用通用的析构[协议](https://nim-lang.org/docs/destructors.html).

如何编写一个可以在运行时增长而不存储容量的数组，留给读者一个练习。编码快乐！



## 向 Nim 捐赠

Nim 是免费的开源软件。我们的工作和时间都不是免费的。请赞助我们的工作！

您可以通过以下方式捐款：
- [开放集体](https://opencollective.com/nim)
- [奖赏来源](https://salt.bountysource.com/teams/nim)
- [PayPal](https://www.paypal.com/donate/?hosted_button_id=KYXH3BLJBHZTA)
- 比特币钱包：1BXfuKM2uvoD6mbx4g5xM3eQhLzkCK77tJ

如果您是一家公司，我们也乐意提供商业支持。


