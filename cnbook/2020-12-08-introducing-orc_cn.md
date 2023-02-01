{==+==}
---
title: "ORC - Vorsprung durch Algorithmen"
author: Araq
excerpt: "ORC -  Algorithmic Advantages"
---
{==+==}
---
title: " ORC - 卓越的 GC 算法"
author: Araq
翻译: Ideages
excerpt: "ORC 算法 优势"
---
{==+==}


{==+==}
Version 1.4 ships with the so-called ORC memory management algorithm.
ORC is the existing ARC algorithm (first shipped in version 1.2) plus a cycle collector. That's also where the name comes from -- the "O" stands for a cycle and "RC" stands for "reference counting", which is the algorithm's foundation.
{==+==}
# ORC - 卓越的 GC 算法

Nim 1.4 带来了 ORC 内存管理算法。
ORC 就是在原 ARC 算法（1.2版本首次发布） 上插入了循环收集器。这也是这个名字的由来 — “O”代表循环，“RC”代表“引用计数”，也是这个算法的基础。
{==+==}


{==+==}
The cycle collector is based on the pretty well known "trial deletion"
algorithm by Lins and others. I won't describe here how this algorithm
works -- you can read
[the paper](https://researcher.watson.ibm.com/researcher/files/us-bacon/Bacon01Concurrent.pdf)
for a good description.
{==+==}
循环收集器基于 Lins 等人广为人知的“试验删除”算法。我不在这里详述这个算法如何工作，细节请阅读[论文（地址已经失效）](https://researcher.watson.ibm.com/researcher/files/us-bacon/Bacon01Concurrent.pdf)。
{==+==}


{==+==}
As usual, I couldn't resist the temptation to improve the algorithm and add more optimizations: The Nim compiler analyses the involved types and only if it is potentially cyclic, code is produced that calls into the cycle collector. This type analysis can be helped out by annotating a type as `acyclic`. For example, this is how a binary tree could be modeled:
{==+==}
我无法抗拒这些诱惑：改进算法并添加更多优化，Nim 编译器分析所涉及的类型，只有当它可能循环引用时，才会生成调用循环收集器的代码。将类型标记为非循环 `acyclic` ，可以帮助进行这种类型分析。例如，新建一个二叉树类型：
{==+==}


{==+==}
```nim
type
  Node {.acyclic.} = ref object
    kids: array[2, Node]
    data: string
```
{==+==}
```nim
type
  Node {.acyclic.} = ref object
    kids: array[2, Node]
    data: string
```
{==+==}


{==+==}
Unfortunately, the overhead of the cycle collector can be measurable in practice. This annotation can be crucial in order to get ORC's performance close to ARC's.
{==+==}
不幸的是，循环收集器的开销在实践中是可以测量的。为了使 ORC 的性能接近 ARC ，这一标记至关重要。
{==+==}


{==+==}
An innovation in ORC's design is that cyclic root candidates can be registered and unregistered in constant time O(1). The consequence is that at runtime we exploit the fact that data in Nim is rarely cyclic.
{==+==}
ORC 设计的一个创新是，循环认定的根对象可以在恒定时间 O(1) 内注册和注销。我们利用了在运行时中的发现，即 Nim 中的数据是很少循环的。
{==+==}


{==+==}
## ARC

ARC is Nim's pure reference-counting GC, however, many reference count
operations are optimized away: Thanks to move semantics, the
construction of a data structure does not involve RC operations. And
thanks to "cursor inference", another innovation of Nim's ARC
implementation, common data structure traversals do not involve RC
operations either! The performance of both ARC and ORC is independent of
the size of the heap.
{==+==}
## ARC

ARC 是 Nim 的纯引用计数 GC ，然而，许多引用计数操作(RC)被优化了：得益于移动语义，数据结构的内存分配不用 RC 了。得益于 ARC 实现的另一项创新“游标推断”("cursor inference"),通用数据结构遍历也不用 RC 了。ARC 和 ORC 的性能与堆的大小无关了。
{==+==}


{==+==}

## Benchmark

To put some weight behind my words, I wrote a simple benchmark showing
off these *algorithmic* differences. Please note that the benchmark was
written to stress the differences between ORC and Nim's other GCs; it's
not supposed to model realistic workloads (yet!).
{==+==}
## 基准测试
为了证明 ORC 的威力，我写了一个简单的基准测试，展示了这些算法上的差异。请注意，编写基准是为了强调 ORC 和 其他 Nim 的 GC 之间的差异；它不应该建模现实的工作负载（现在！）。
{==+==}


{==+==}

<div class="language-nim highlighter-rouge"><pre class="highlight"><code>
<table class="line-nums-table"><tbody><tr><td class="blob-line-nums">1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
</td><td><span class="k">import</span> <span class="Identifier">asynchttpserver</span><span class="Punctuation">,</span> <span class="Identifier">asyncdispatch</span><span class="Punctuation">,</span> <span class="Identifier">strutils</span><span class="Punctuation">,</span> <span class="Identifier">json</span><span class="Punctuation">,</span> <span class="Identifier">tables</span><span class="Punctuation">,</span> <span class="Identifier">streams</span>

<span class="Comment"># about 135 MB of live data:</span>
<span class="k">var</span> <span class="Identifier">sessions</span><span class="Punctuation">:</span> <span class="Identifier">Table</span><span class="Punctuation">[</span><span class="Identifier">string</span><span class="Punctuation">,</span> <span class="Identifier">JsonNode</span><span class="Punctuation">]</span>
<span class="k">for</span> <span class="Identifier">i</span> <span class="k">in</span> <span class="mi">0</span> <span class="Operator">..&lt;</span> <span class="mi">10</span><span class="Punctuation">:</span>
  <span class="Identifier">sessions</span><span class="Punctuation">[</span><span class="Operator">$</span><span class="Identifier">i</span><span class="Punctuation">]</span> <span class="Operator">=</span> <span class="Identifier">parseJson</span><span class="Punctuation">(</span><span class="Identifier">newFileStream</span><span class="Punctuation">(</span><span class="s">&quot;1.json&quot;</span><span class="Punctuation">,</span> <span class="Identifier">fmRead</span><span class="Punctuation">)</span><span class="Punctuation">,</span> <span class="s">&quot;1.json&quot;</span><span class="Punctuation">)</span>

<span class="k">var</span> <span class="Identifier">served</span> <span class="Operator">=</span> <span class="mi">0</span>

<span class="k">var</span> <span class="Identifier">server</span> <span class="Operator">=</span> <span class="Identifier">newAsyncHttpServer</span><span class="Punctuation">(</span><span class="Punctuation">)</span>
<span class="k">proc</span> <span class="nf">cb</span><span class="Punctuation">(</span><span class="Identifier">req</span><span class="Punctuation">:</span> <span class="Identifier">Request</span><span class="Punctuation">)</span> <span class="Punctuation">{</span><span class="Operator">.</span><span class="Identifier">async</span><span class="Operator">.</span><span class="Punctuation">}</span> <span class="Operator">=</span>
  <span class="Identifier">inc</span> <span class="Identifier">served</span>
  <span class="Identifier">await</span> <span class="Identifier">req</span><span class="Operator">.</span><span class="Identifier">respond</span><span class="Punctuation">(</span><span class="Identifier">Http200</span><span class="Punctuation">,</span> <span class="s">&quot;Hello World&quot;</span><span class="Punctuation">)</span>
  <span class="k">if</span> <span class="Identifier">served</span> <span class="k">mod</span> <span class="mi">10</span> <span class="Operator">==</span> <span class="mi">0</span><span class="Punctuation">:</span>
    <span class="k">when</span> <span class="k">not</span> <span class="Identifier">defined</span><span class="Punctuation">(</span><span class="Identifier">memForSpeed</span><span class="Punctuation">)</span><span class="Punctuation">:</span>
      <span class="Identifier">GC_fullCollect</span><span class="Punctuation">(</span><span class="Punctuation">)</span>

<span class="Identifier">waitFor</span> <span class="Identifier">server</span><span class="Operator">.</span><span class="Identifier">serve</span><span class="Punctuation">(</span><span class="Identifier">Port</span><span class="Punctuation">(</span><span class="mi">8080</span><span class="Punctuation">)</span><span class="Punctuation">,</span> <span class="Identifier">cb</span><span class="Punctuation">)</span></td></tr></tbody></table>
</code></pre>
</div>
{==+==}
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
{==+==}


{==+==}
Lines 10-18 are the "Hello World" asynchronous HTTP server example from Nim's standard library.
In lines 4-6, we load about 135MB of JSON data into the global `sessions` variable.
ORC never touches this memory after it has been loaded, even though it remains alive for the rest of the program run. The older Nim GCs do have to touch this memory.
I compare ORC to Nim's "mark and sweep" GC (M&S) as M&S performs best on this benchmark.
{==+==}
第10-18行是Nim标准库中的 “HelloWorld” 异步HTTP服务器示例。
在4-6行中，我们将大约135MB的 JSON 数据加载到全局变量 `sessions` 中。
ORC 在加载后从未接触过这个内存，即使它在程序运行的其余时间都保持活动状态。老版本的Nim GC 确实需要接触这些内存。
我将 ORC 与 Nim 的“标记和清除” GC（M&S）进行比较，因为 M&S 在这个基准测试上表现最好。
{==+==}


{==+==}
`GC_fullCollect` is called frequently in order to keep the memory
consumption close to the 135MB of RAM that the program needs in theory.

With the "wrk" benchmarking tool I get these numbers:

| Metric / algorithm | ORC         | M&S       |
| ------------------ | ----------: | --------: |
| Latency (Avg)      | 320.49 *u*s | 65.31 ms  |
| Latency (Max)      | 6.24 ms     | 204.79 ms |
| Requests/sec       | 30963.96    | 282.69    |
| Transfer/sec       | 1.48 MB     | 13.80 KB  |
| Max memory         | 137 MiB     | 153 MiB   |
{==+==}
``GC_fullCollect``被频繁调用，以使内存消耗接近理论上程序所需的135MB。

使用 ``wrk`` 基准测试工具，得到以下数据：

| 指标/算法 | ORC         | M&S       |
| -------  | --------: | --------: |
| 耗时 (平均)   | 320.49 *u*s | 65.31 ms  |
| 耗时 (最大)   | 6.24 ms     | 204.79 ms |
| 请求/秒       | 30963.96    | 282.69    |
| 传输/秒       | 1.48 MB     | 13.80 KB  |
| 最大内存      | 137 MiB     | 153 MiB   |
{==+==}


{==+==}
That's right, ORC is **over 100 times faster** than the M&S GC. The reason is that ORC only touches memory that the mutator touches, too.
This is a key feature that allows reasoning about performance on modern machines. A generational GC could probably offer comparable guarantees.
In fact, ORC can be seen as a generational and incremental GC with the additional guarantee that acyclic structures are freed as soon as they become garbage.
{==+==}
没错，ORC 比 M&S GC **快100倍**。原因是 ORC 只接触赋值操作的内存。
这是一个关键特性，可以让现代机器的性能符合理论数据。新一代垃圾收集器可以提供相同的保证。
事实上，ORC 是新一代的改进垃圾收集器，它额外保证，非循环结构一旦变成垃圾就会被释放。
{==+==}


{==+==}
Now what happens when the aggressive `GC_fullCollect` calls are not
done? I get these numbers:

| Metric / algorithm | ORC         | M&S (memForSpeed) |
| ------------------ | ----------: | ----------------: |
| Latency (Avg)      | 274.84 *u*s | 1.49 ms           |
| Latency (Max)      | 1.10 ms     | 46.41 ms          |
| Requests/sec       | 34948.95    | 39561.97          |
| Transfer/sec       | 1.67 MB     | 1.89 MB           |
| Max memory         | 137 MiB     | 333 MiB           |
{==+==}
现在，看看主动的``GC_fullCollect``调用做了什么?我得到这些数据:
| 指标/算法 | ORC         | M&S (memForSpeed) |
| ------- | ----------: | ----------------: |
| 平均耗时  | 274.84 *u*s | 1.49 ms           |
| 最大耗时  | 1.10 ms     | 46.41 ms          |
| 请求/秒   | 34948.95    | 39561.97          |
| 传输/秒   | 1.67 MB     | 1.89 MB           |
|最大内存使用| 137 MiB     | 333 MiB           |
{==+==}


{==+==}
M&S now wins in throughput, but not in latency. However, the memory
consumption rises to about 330MB; more than twice as much memory as the
program really requires!
{==+==}
 M&S 现在的优势是吞吐量，耗时还不是。然而，内存消耗量上升至约330MB，内存是程序真正需要的两倍。
{==+==}


{==+==}
ORC always wins on latency and memory consumption; plays nice with destructors, and hence with custom memory management; is independent of the heap sizes; tracks stack roots precisely and works cleanly with all sanitizers the C/C++ ecosystem offers.
{==+==}
ORC 总是在延迟和内存消耗方面获胜；与析构函数配合得很好，因此与自定义内存管理配合得也很好；且与堆大小无关；能精确跟踪堆栈根，并与C/C++生态系统提供的所有清扫机制一起干净地工作。
{==+==}


{==+==}
These results are typical for what we see in other programs:
Latency is reduced, there is little jitter and the memory consumption remains close to the required minimum that a program needs.
Excellent results for embedded development!
{==+==}
这些结果是我们在其他程序中看到的典型结果：
减少了耗时，几乎没有不稳定，内存消耗接近于程序理论上所需的最小值。
用在嵌入式系统开发上太卓越了！
{==+==}


{==+==}
Further advancements to the cycle collection algorithm itself are in development;
it turns out there are lots of ideas that the GC research overlooked.
Exciting times for Nim!

{==+==}
对循环收集算法本身的进一步改进正在开发中；
事实证明，垃圾回收算法研究忽略了很多想法。
Nim 的兴奋时刻！
{==+==}


{==+==}

## Summary

To compile your code with ORC, use `--gc:orc` on the command line.

- ORC works out of the box with Valgrind and other C++ sanitizers.
  (Compile with `--gc:orc -g -d:useMalloc` for precise Valgrind
  checking.)
- ORC uses 2x less memory than classical GCs.
- ORC can be orders of magnitudes faster in throughput when memory consumption is important. It is comparable in throughput when memory consumption is not as important.
- ORC uses no CPU specific tricks; it works without hacks even on limited targets like Webassembly.
- ORC offers sub-millisecond latencies. It is well suited for (hard) realtime systems. There is no "stop the world" phase.
- ORC is oblivious to the size of the heap or the used stack space.

{==+==}

## 小结

要使用 ORC 编译代码，请在使用 `--gc:ORC` 命令。
- ORC 与 Valgrind（内存检测工具） 和其他C++ 回收机制一起开箱即用。（使用 `--gc:orc-g-d:useMalloc` 编译以获得精确的 Valgrind 检查。）
-ORC 耗费的内存比传统 GC少2倍。
- 当内存消耗很重要时，ORC的吞吐量可能会快几个数量级。当内存消耗不那么重要时，它们的吞吐量相当。
- ORC 不使用 CPU 特定的技术；即使编译成 Webassembly ，它也会工作的很好。
- ORC 提供亚毫秒延迟。它非常适合（硬）实时系统。没有“全局暂停”阶段。
- ORC 不用关心使用的堆或栈的大小。
{==+==}


{==+==}

----

If you like this article and how we evolve Nim, please consider a
donation. You can donate via:

- [Open Collective](https://opencollective.com/nim)
- [Patreon](https://www.patreon.com/araq)
- [PayPal](https://www.paypal.com/donate/?hosted_button_id=KYXH3BLJBHZTA)
- Bitcoin: bc1qzgw3vsppsa9gu53qyecyu063jfajmjpye3r2h4
- Ethereum: 0xC1d472B409c1bdCd8C0E45515D18F08a55fE9fa8

If you are a company, we also offer commercial support. Please get in
touch with us via <support@nim-lang.org>. As a commercial backer, you
can decide what features and bugfixes should be prioritized.
{==+==}

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
{==+==}
