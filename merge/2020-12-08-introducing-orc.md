---
title: " ORC - 卓越的 GC 算法"
author: Araq
翻译: Ideages
excerpt: "ORC 算法 优势"
---

# ORC - 卓越的 GC 算法

Nim 1.4 带来了 ORC 内存管理算法。
ORC 就是在原 ARC 算法（1.2版本首次发布） 上插入了循环收集器。这也是这个名字的由来 — “O”代表循环，“RC”代表“引用计数”，也是这个算法的基础。

循环收集器基于 Lins 等人广为人知的“试验删除”算法。我不在这里详述这个算法如何工作，细节请阅读[论文（地址已经失效）](https://researcher.watson.ibm.com/researcher/files/us-bacon/Bacon01Concurrent.pdf)。

我无法抗拒这些诱惑：改进算法并添加更多优化，Nim 编译器分析所涉及的类型，只有当它可能循环引用时，才会生成调用循环收集器的代码。将类型标记为非循环 `acyclic` ，可以帮助进行这种类型分析。例如，新建一个二叉树类型：

```nim
type
  Node {.acyclic.} = ref object
    kids: array[2, Node]
    data: string
```

不幸的是，循环收集器的开销在实践中是可以测量的。为了使 ORC 的性能接近 ARC ，这一标记至关重要。

ORC 设计的一个创新是，循环认定的根对象可以在恒定时间 O(1) 内注册和注销。我们利用了在运行时中的发现，即 Nim 中的数据是很少循环的。

## ARC

ARC 是 Nim 的纯引用计数 GC ，然而，许多引用计数操作(RC)被优化了：得益于移动语义，数据结构的内存分配不用 RC 了。得益于 ARC 实现的另一项创新“游标推断”("cursor inference"),通用数据结构遍历也不用 RC 了。ARC 和 ORC 的性能与堆的大小无关了。

## 基准测试
为了证明 ORC 的威力，我写了一个简单的基准测试，展示了这些算法上的差异。请注意，编写基准是为了强调 ORC 和 其他 Nim 的 GC 之间的差异；它不应该建模现实的工作负载（现在！）。

```nim
import asynchttpserver, asyncdispatch, strutils, json, tables, streams

# about 135 MB of live data:
var sessions: Table[string, JsonNode]
for i in 0 ..< 10:
  sessions[$i] = parseJson(newFileStream("1.json", fmRead), "1.json")

var served = 0

var server = newAsyncHttpServer()
proc cb(req: Request) {.async.} =
  inc served
  await req.respond(Http200, "Hello World")
  if served mod 10 == 0:
    when not defined(memForSpeed):
      GC_fullCollect()

waitFor server.serve(Port(8080), cb)
```

第10-18行是Nim标准库中的 “HelloWorld” 异步HTTP服务器示例。
在4-6行中，我们将大约135MB的 JSON 数据加载到全局变量 `sessions` 中。
ORC 在加载后从未接触过这个内存，即使它在程序运行的其余时间都保持活动状态。老版本的Nim GC 确实需要接触这些内存。
我将 ORC 与 Nim 的“标记和清除” GC（M&S）进行比较，因为 M&S 在这个基准测试上表现最好。

``GC_fullCollect``被频繁调用，以使内存消耗接近理论上程序所需的135MB。

使用 ``wrk`` 基准测试工具，得到以下数据：

| 指标/算法 | ORC         | M&S       |
| -------  | --------: | --------: |
| 耗时 (平均)   | 320.49 *u*s | 65.31 ms  |
| 耗时 (最大)   | 6.24 ms     | 204.79 ms |
| 请求/秒       | 30963.96    | 282.69    |
| 传输/秒       | 1.48 MB     | 13.80 KB  |
| 最大内存      | 137 MiB     | 153 MiB   |

没错，ORC 比 M&S GC **快100倍**。原因是 ORC 只接触赋值操作的内存。
这是一个关键特性，可以让现代机器的性能符合理论数据。新一代垃圾收集器可以提供相同的保证。
事实上，ORC 是新一代的改进垃圾收集器，它额外保证，非循环结构一旦变成垃圾就会被释放。


现在，看看主动的``GC_fullCollect``调用做了什么?我得到这些数据:

| 指标/算法 | ORC         | M&S (memForSpeed) |
| ------- | ----------  | ---------------- |
| 平均耗时  | 274.84 *u*s | 1.49 ms           |
| 最大耗时  | 1.10 ms     | 46.41 ms          |
| 请求/秒   | 34948.95    | 39561.97          |
| 传输/秒   | 1.67 MB     | 1.89 MB           |
|最大内存使用| 137 MiB     | 333 MiB           |


M&S 现在的优势是吞吐量，耗时还不是。然而，内存消耗量上升至约330MB，内存是程序真正需要的两倍。

ORC 总是在延迟和内存消耗方面获胜；与析构函数配合得很好，因此与自定义内存管理配合得也很好；且与堆大小无关；能精确跟踪堆栈根，并与C/C++生态系统提供的所有清扫机制一起干净地工作。

这些结果是我们在其他程序中看到的典型结果：
减少了耗时，几乎没有不稳定，内存消耗接近于程序理论上所需的最小值。
用在嵌入式系统开发上太卓越了！

对循环收集算法本身的进一步改进正在开发中；
事实证明，垃圾回收算法研究忽略了很多想法。
Nim 的兴奋时刻！


## 小结

要使用 ORC 编译代码，请在使用 `--gc:ORC` 命令。
- ORC 与 Valgrind（内存检测工具） 和其他C++ 回收机制一起开箱即用。（使用 `--gc:orc -g -d:useMalloc` 编译以获得精确的 Valgrind 检查。）
-ORC 耗费的内存比传统 GC少2倍。
- 当内存消耗很重要时，ORC的吞吐量可能会快几个数量级。当内存消耗不那么重要时，它们的吞吐量相当。
- ORC 不使用 CPU 特定的技术；即使编译成 Webassembly ，它也会工作的很好。
- ORC 提供亚毫秒延迟。它非常适合（硬）实时系统。没有“全局暂停”阶段。
- ORC 不用关心使用的堆或栈的大小。


### 译者做的测试

工作环境：Nim1.6.10 ``data-1.0.json`` 为vue的文件,MacBook Air,四核Intel Core i5,8G.

- ARC 工作的最好。 
- ORC 也差不多，这两个算法吞吐量很好。耗费内存在运行时由 300M 增加 到4G。
- Refc 工作的很差。但不耗费内存：内存由启动时候的 400M 增加到 411M。


| 指标/算法 | ORC         | Refc       | ARC       |
| -------  | --------: | --------: | --------: |
| 耗时 (平均)   | 2.27ms | 133.71ms  |2.14ms  |
| 耗时 (最大)   | 51.43ms     | 1.61s |53.50ms |
| 请求/秒       | 42254.33    | 282.69    |44763.49    |
| 传输/秒       | 2.01MB     | 1.17KB  |2.13MB |
| 最大内存      | 4 GB     | 411 MB   | 4 GB   |

以上结果，仅供参考。

----

如果您喜欢这篇文章以及帮助Nim发展，请考虑捐赠，您可以通过以下方式捐款：
- [开放集体](https://opencollective.com/nim)
- [募集网站](https://www.patreon.com/araq)
- [PayPal](https://www.paypal.com/donate/?hosted_button_id=KYXH3BLJBHZTA)
- 比特币：bc1qzgw3vsppsa9gu53qyecyu063jfajmjpye3r2h4
- 以太坊：0xC1d472B409c1bdCd8C0E45515D18F08a55fE9fa8
如果您是一家公司，我们也可以提供商业支持。请通过<support@nim-lang.org>与我们联系。作为商业支持者，您可以决定优先考虑功能实现和错误修复。
