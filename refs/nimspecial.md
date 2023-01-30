Nim 语言有哪些特点
===============

题叶 发布于 2015-03-04

ideage 编辑了部分 于 2023-01-30

原文: http://hookrace.net/blog/what-is-special-about-nim/

原译文：https://segmentfault.com/a/1190000002576013

Nim 编程语言很让人振奋. 官方教程虽然很棒, 但只是慢吞吞介绍语言.
而我打算快速向你栈是用 Nim 能做的, 在其他语言很难或者做不到的事情.

我发现 Nim 是在我为开发游戏(HookRace)寻找一个正确的工具的时候,
这个游戏是我的 DDNet 游戏(mod of Teeworlds)后续的版本.
因为我最近忙着别的项目, 所以这个博客主要就关于 Nim 了, 直到我有时间继续开发游戏.

**容易运行**

好吧, 这个部分不见得有意思, 但我邀请你跟着文章一起来执行代码:

```nim
for i in 0..10:
  echo "Hello World"[0..i]
```

这之前, 安装 Nim 编译器.
将代码保存为 `hello.nim` , 用 `nim c hello` 编译, 再用 `./hello` 运行二进制文件.
要同时编译和运行, 使用 `nim -r c hello`.
要使用优化过` release build`, 而不是 `debug build `的话, 使用 `nim -d:release c hello`.
上面所有的配置你都可以看到下面的输出:

```bash
H
He
Hel
Hell
Hello
Hello
Hello W
Hello Wo
Hello Wor
Hello Worl
Hello World
```

**在编译期间运行普通代码**

要实现一个高效的 `CRC32` 程序你需要查一个表.
你可以在运行时计算, 或者在源码当中使用 `magic array` 写好.
我们这里明确一下不想要任何的 `magic number `出现在代码中, 所以(这时候)我们在运行时做:

```nim
import unsigned, strutils

type CRC32* = uint32
const initCRC32* = CRC32(-1)

proc createCRCTable(): array[256, CRC32] =
  for i in 0..255:
    var rem = CRC32(i)
    for j in 0..7:
      if (rem and 1) > 0: rem = (rem shr 1) xor CRC32(0xedb88320)
      else: rem = rem shr 1
    result[i] = rem

# Table created at runtime
var crc32table = createCRCTable()

proc crc32(s): CRC32 =
  result = initCRC32
  for c in s:
    result = (result shr 8) xor crc32table[(result and 0xff) xor ord(c)]
  result = not result

# String conversion proc $, automatically called by echo
proc `$`(c: CRC32): string = int64(c).toHex(8)

echo crc32("The quick brown fox jumps over the lazy dog")
```

好, 运行成功了, 我们得到输出 `414FA339`.
但是如果我们能在编译过程中计算 `CRC` 表就更好了.
在 Nim 当中这非常容易, 替换掉 `crc32table` 的代码, 我们使用:

```nim
# Table created at compile time
const crc32table = createCRCTable()
```

是的, 就是这样: 我们索要做的仅仅是把 `var` 换成是 `const`. 很妙吧?
我们可以写同样的代码, 让它在运行时, 或者编译时执行. 不需要 `template`, 不需要元编程.

**对语言进行扩展**

`templates` 和 `macros` 可用于替换模版, 在编译时变换代码.

`templates` 仅仅在是在编译时把调用它们的代码换成它们的实际代码.
我们可以自己定义一个循环:

```nim
template times(x: expr, y: stmt): stmt =
  for i in 1..x:
    y

10.times:
  echo "Hello World"
```

那么编译器就会吧 `times` 循环的代码变换为普通的 `for` 循环:

```nim
for i in 1..10:
  echo "Hello World"
```

如果你想问 `10.times` 的语法.. 它就是一个通常的 `times` 的调用,
`10` 是这个调用的第一个参数, 后面跟着一个 `block` 作为第二个参数
换句话说你也可以写 `times(10);`, 参考统一的调用语法.

或者更轻松地初始化序列(变长的 `array` ):

```nim
template newSeqWith(len: int, init: expr): expr =
  var result = newSeq[type(init)](len)
  for i in 0 .. <len:
    result[i] = init
  result

# 创建一个 2 维的序列, 大小为 20,10
var seq2D = newSeqWith(20, newSeq[bool](10))

import math
randomize()
# 创建一个序列, 其中有 20 个随机整数, 每个小于 10
var seqRand = newSeqWith(20, random(10))
echo seqRand
```nim

`macros` 走得更远异步, 让你能分析还有操作 `AST`.
在 Nim 当中没有列表剖析, 但是, 你可以做到比如说[用 `macro` 把这个功能加进来].
那么对于下面的代码:

```nim
var res: seq[int] = @[]
for x in 1..10:
  if x mod 2 == 0:
    res.add(x)
echo res

const n = 20
var result: seq[tuple[a,b,c: int]] = @[]
for x in 1..n:
  for y in x..n:
    for z in y..n:
      if x*x + y*y == z*z:
        result.add((x,y,z))
echo result
```

你可以借助 `future` 模块写成:

```nim
import future
echo lc[x | (x <- 1..10, x mod 2 == 0), int]
const n = 20
echo lc[(x,y,z) | (x <- 1..n, y <- x..n, z <- y..n,
                   x*x + y*y == z*z), tuple[a,b,c: int]]

```

**向编译器加入加入你自己的优化**

相对于优化自己的代码, 你不会考虑把编译器变得更聪明吗? 在 Nim 你就可以!

```nim
var x: int
for i in 1..1_000_000_000:
  x += 2 * i
echo x
```

这些代码(实际上没啥用)课以通过教会编译器两种优化来加速:

```nim
template optMul{`*`(a,2)}(a: int): int =
  let x = a
  x + x

template canonMul{`*`(a,b)}(a: int{lit}, b: int): int =
  b * a
```

第一个是 term rewriting `template` 我们指定 `a * 2` 可以替换为 `a + a`.
第二个我们指定乘法当中如果第一个是整型的字面量那么 `int` 可以被交换, 于是就有可能应用第一个 `tempalte`.

更复杂的模式也可以实现, 比如优化 `boolean` 的逻辑:

```nim
template optLog1{a and a}(a): auto = a
template optLog2{a and (b or (not b))}(a,b): auto = a
template optLog3{a and not a}(a: int): auto = 0

var
  x = 12
  s = x and x
  # Hint: optLog1(x) --> ’x’ [Pattern]

  r = (x and x) and ((s or s) or (not (s or s)))
  # Hint: optLog2(x and x, s or s) --> ’x and x’ [Pattern]
  # Hint: optLog1(x) --> ’x’ [Pattern]

  q = (s and not x) and not (s and not x)
  # Hint: optLog3(s and not x) --> ’0’ [Pattern]
```

`s` 直接被优化为 `x` , 通过两次连续的模式应用优化为 `2`, `q` 马上得到 `0` .

如果你想看用 term rewriting `tempalte` 怎么避免写大整数的内存分配,
查一下 `bigints` 模块 当中 `opt` 开头的 `templates`:

```nim
import bigints

var i = 0.initBigInt
while true:
  i += 1
  echo i
```

绑定你喜欢的 C 函数和类库
因为 Nim 是编译的 C 的, 外部函数接口很有意思.

你可以很容易用上 C 模块库当中你喜欢的函数:

```nim
proc printf(formatstr: cstring)
  {.header: "<stdio.h>", varargs.}
printf("%s %d\n", "foo", 5)
```

或者使用你自己用 C 写的代码:

```c
// 保存为 hi.c
void hi(char* name) {
  printf("awesome %s\n", name);
}
```

```nim
{.compile: "hi.c".}
proc hi*(name: cstring) {.importc.}
hi "from Nim"
```
或者借助 `c2nim` 使用任何你想要的:

**控制垃圾回收**

为了达到 `soft realtime`, 你可以指定垃圾收集器什么时候还有多久被允许运行.
游戏的主要逻辑在 `Nim` 当中可以这样实现, 用来避免垃圾收集器导致卡顿:

```nim
gcDisable()
while true:
  gameLogic()
  renderFrame()
  gcStep(us = leftTime)
  sleep(restTime)
```

**类型安全的集合和 `enums` 的 `array`**

你经常用到数学的集合来容纳你自己定义的值, 这是类型安全的写法:

```nim
type FakeTune = enum
  freeze, solo, noJump, noColl, noHook, jetpack

var x: set[FakeTune]

x.incl freeze
x.incl solo
x.excl solo

echo x + {noColl, noHook}

if freeze in x:
  echo "Here be freeze"

var y = {solo, noHook}
y.incl 0 # Error: type mismatch
```

你不会意外地加入另一个类型的值. 集合的内部实现是一个高效的 `bitvector`.

对 `array` 来说可以可以的, 用 `enum` 来索引它们:

```nim
var a: array[FakeTune, int]
a[freeze] = 100
echo a[freeze]
```

**统一的调用语法**

这只是语法糖, 但是有的话是很好的. 在 Python 里我常忘记 `len` 和 `append` 是函数是方法.
在 Nim 里我不需要记忆, 因为两种写法是一样. Nim 使用统一的调用语法,
这也被人提议给了 C++, 两个人是 [Herb Sutter][HB] 和 Bjarne Stroustrup.

```nim
var xs = @[1,2,3]

# Procedure call syntax
add(xs, 4_000_000)
echo len(xs)

# Method call syntax
xs.add(0b0101_0000_0000)
echo xs.len()

# Command invocation syntax
xs.add 0x06_FF_FF_FF
echo xs.len
```

**优良的性能**

用 Nim 写高效的代码很容易, 这可以在 [Longest Path Finding Benchmark:BPATH](https://github.com/logicchains/LPATHBench/blob/master/writeup.md) 看出来,
其中 [Nim](https://github.com/logicchains/LPATHBench/blob/master/nim.nim) 用相当漂亮的代码完成了.

测试最开始发布的时候我在自己的机器上做了一些测算:
(Linux x86-64, Intel Core2Quad Q9300 @2.5GHz, state of 2014-12-20)

语言 | Time[ms] | Memory[KB] | 编译时间[ms] |代码压缩后体积[B] |
|-----|------|------|-----|-----|
| Nim | 1400 | 1460 | 893 | 486 |
| C++ | 1478 | 2717 | 774 | 728 | 
| D   | 1518 | 2388 | 1614 | 669 | 
| Rust | 1623 | 2632 | 6735 | 934 | 
| Java  | 1874 | 24428 | 812 | 778 | 
| OCaml | 2384 | 4496 | 125 | 782 | 
| Go  | 3116 | 1664 | 596 | 618 | 
| Haskell | 3329 | 5268 | 3002 | 1091 | 
| LuaJit | 3857 | 2368 | - | 519 | 
| Lisp | 8219 | 15876 | 1043 | 1007 | 
| Racket| 8503 | 130284 | 24793 | 741 | 

代码体积的压缩使用了 `gzip -9 < nim.nim | wc -c` . 也移除了 Haskell 中无用的代码.

编译时间就是完整的编译, 如果你用 `nimcache` 缓存了标准库的预编译, Nim 就只要 323ms.

我做过另一个小的测试, 计算开头 `100M` 自然数当中那些是质数, 对比 Python, Nim 和 C:

Python (运行时间: 35.1s)
```python
def eratosthenes(n):
  sieve = [1] * 2 + [0] * (n - 1)
  for i in range(int(n**0.5)):
    if not sieve[i]:
      for j in range(i*i, n+1, i):
        sieve[j] = 1
  return sieve

eratosthenes(100000000)
```

Nim(运行时间: 2.6s)

```nim
import math

proc eratosthenes(n): auto =
  result = newSeq[int8](n+1)
  result[0] = 1; result[1] = 1

  for i in 0 .. int sqrt(float n):
    if result[i] == 0:
      for j in countup(i*i, n, i):
        result[j] = 1

discard eratosthenes(100_000_000)
```

C(运行时间: 2.6s)

```c
#include <stdlib.h>
#include <math.h>
char* eratosthenes(int n)
{
  char* sieve = calloc(n+1,sizeof(char));
  sieve[0] = 1; sieve[1] = 1;
  int m = (int) sqrt((double) n);

  for(int i = 0; i <= m; i++) {
    if(!sieve[i]) {
      for (int j = i*i; j <= n; j += i)
        sieve[j] = 1;
    }
  }
  return sieve;
}

int main() {
  eratosthenes(100000000);
}
```

**编译到 JavaScript**

你可以 把 Nim 编译到 JavaScript , 而不是 C.
这样你就可以直接用 Nim 写一些客户端, 也可以写服务端.
我们来写一个服务端的访问用户统计, 在浏览器上显示出来. 这是 `client.nim`:

```nim
import htmlgen, dom

type Data = object
  visitors {.importc.}: int
  uniques {.importc.}: int
  ip {.importc.}: cstring

proc printInfo(data: Data) {.exportc.} =
  var infoDiv = document.getElementById("info")
  infoDiv.innerHTML = p("You're visitor number ", $data.visitors,
    ", unique visitor number ", $data.uniques,
    " today. Your IP is ", $data.ip, ".")
```

我们定义 `Data` 类型, 用来从服务器传递给客户端.
`printInfo` 程序会用 `data` 调用, 然后显示.
使用` nim js client `编译. 变异结果的 JavaScript 文件在 `nimcache/client.js`.

对于服务器我们需要用到 Nimble 包管理器然后运行 `nimble install jester`.
之后我们可以用上 Jest Web 框架来写 `server.nim`:

```nim
import jester, asyncdispatch, json, strutils, times, sets, htmlgen, strtabs

var
  visitors = 0
  uniques = initSet[string]()
  time: TimeInfo

routes:
  get "/":
    resp body(
      `div`(id="info"),
      script(src="/client.js", `type`="text/javascript"),
      script(src="/visitors", `type`="text/javascript"))

  get "/client.js":
    const result = staticExec "nim -d:release js client"
    const clientJS = staticRead "nimcache/client.js"
    resp clientJS

  get "/visitors":
    let newTime = getTime().getLocalTime
    if newTime.monthDay != time.monthDay:
      visitors = 0
      init uniques
      time = newTime

    inc visitors
    let ip =
      if request.headers.hasKey "X-Forwarded-For":
        request.headers["X-Forwarded-For"]
      else:
        request.ip
    uniques.incl ip

    let json = %{"visitors": %visitors,
                 "uniques": %uniques.len,
                 "ip": %ip}
    resp "printInfo($#)".format(json)

runForever()
```

这个服务器就包含了主要的网页. 同样也包含了 `client.js`, 用过在编译时读取编译 `client.nim`.
逻辑在 `/visitors` 当中处理.
用 `nim -r c server` 编译运行, 打开 http://localhost:5000/ 查看效果.

你可以在 [Jester 生成的网站](https://hookrace.net/visitors/visitors)上看代码执行效果, 或者下面内联的:

内联 HTML(没有内容)

**尾声**

我希望我能激发你对 Nim 语言的兴趣.

注意这门语言还没有完全稳定下来. 特别是一些含糊的功能你可能会遇到 bug.
但是好的一面是, Nim 1.0 计划在未来 3 个月里发布! 所以现在开始学习 Nim 是很好的时机.

奖励: 因为 Nim 编译到 C 而且只依赖 C 标准库, 你可以在任何地方部署,
包括 x86-64, ARM 和 Intel Xeon Phi accelerator cards.

评论的话用 Reddit, Hacker News, 或者在 IRC(#nim on freenode) 上直接问 Nim 社区

你可以通过我的个人邮件 dennis@felsin9.de 找到我.

感谢 Andreas Rumpf 和 Dominik Picheta 审阅这篇文章.