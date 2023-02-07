








# Nim 之禅

1. 抄袭糟糕的设计不是好设计。
2. 如果编译器不能推理代码，程序员也不能推理。
3. 不要妨碍程序员。
4. 将工作转移到编译时间：程序运行的频率比编译的频率高。
5. 可定制的内存管理。
6. 简洁的代码与可读性不冲突，它可以提高可读性。
7. 利用元编程保持语言的小型化。
8. 优化是专门化的：需要更快速度时，编写自定义代码。
9. 能做这些事的只有一种编程语言。那就是 Nim 语言。



>**编者按：**
>
>在最初的演示中，Nim 之禅在结尾处给出（没有编号）。
>在这里，我们在一开始就提供了 Nim 之禅 的规则，为了便于参考，对其进行了编号。
>上述规则的讨论是在对语言进行一般性讨论的背景下进行的，没有按照上面的顺序。
>这里的内容是在原始演示之后呈现的，从幻灯片材料和视频记录开始，经过很少的编辑（这导致了非正式的基调）。
>



>目录：
> - 简介
> - 语法（引入Nim并激发规则6：简洁的代码可以提高可读性）
> - 智能编译器（规则2：编译器必须能够推理代码）
> - 元编程功能（通过规则1引入：复制糟糕设计…）
> - 实用语言（规则3：不要妨碍程序员）
> - 可定制内存管理（规则5）
> - Nim 之禅（对所有规则进行回顾和讨论；规则4、7、8、9仅在此讨论）



## 简介

在这篇博文中，我将解释 Nim 语言的哲学，以及为什么 Nim 可以用于广泛的应用领域，例如：

- 科学计算
- 游戏
- 编译器
- 操作系统开发
- 编写脚本
- 其他一切



 `禅` 意味着我们将达成一套指导语言设计和进化的规则（如上所示），
下面将通过示例来了解这些规则。



## 语法

让我通过 Nim 的语法来介绍它。

我知道大多数人可能都知道这门语言，但为了给你们一个简单的介绍，我将解释基本语法，并希望得出有趣的结论。

Nim 使用基于 **缩进的语法** ，其灵感来自 Haskell 或 Python ，**适合 Nim 的宏系统**。




### Function 函数应用程序

Nim 区分语句和表达式，大多数表达式是函数应用程序（也称为 `过程调用` ）。

函数应用程序使用带括号的传统数学语法：`f()`, `f(a)`, `f(a, b)`。

这是语法糖：




|   |  语法糖     |   意思        |   例子         |
|---|------------|--------------|----------------|
| 1 | `f a`     |  `f(a)`            |  `spawn log("some message")`  |
| 2 | `f a, b`  |  `f(a, b)`         |  `echo "hello ", "world"`     |
| 3 | `a.f()`   |  `f(a)`            |  `db.fetchRow()`              |
| 4 | `a.f`     |  `f(a)`            |  `mystring.len`               |
| 5 | `a.f(b)`  |  `f(a, b)`         |  `myarray.map(f)`             |
| 6 | `a.f b`   |  `f(a, b)`         |  `db.fetchRow 1`              |
| 7 | `f"\n"`   |  `f(r"\n")`        |  `re"\b[a-z*]\b"`             |
| 8 | `f a: b`  |  `f(a, b)`         |  `lock x: echo "hi"`          |



* 在函数规则 1 和 2 中，可以省略括号，并提供一些示例，您可以了解为什么能这么用：
`spawn` 看起来像一个关键字，这很好，因为它做了一些特殊的事情；
`echo` 也以省略括号而闻名，因为通常这些语句是为了调试，可以快速完成任务。

* 有一个可用的点符号，可以省略括号（规则 3-6 ）。

* 规则 7 是关于字符串的：`f` 后面跟着一个没有空格的字符串仍然是一个调用，但字符串被转换为原始字符串，这对正则表达式非常方便，因为正则表达式有自己的反斜杠转义符。

* 在最后一条规则中，我们可以看到您可以使用 ``:`` 语法将**代码块**传递给 `f` 。
代码块通常是传递给函数的最后一个参数。这可用于创建自定义 `lock` 语句，类似的 `with`等其他的模板或者宏。

在您希望直接引用 `f` 的情况下，有 **一个例外**，即省略括号的 `f` 不表示 `f()` 。
对于 `myarray.map(f)` ，您不希望调用 `f` ，而是希望将 `f` 本身传递给 `map` 。




### 操作符/运算符

Nim 具有二元操作符和一元操作符：

* 大多数情况下，二元操作符被简单地调用为 `x @ y`，一元操作符为 `@x` 。
* 操作符和函数之间以及二元运算符和一元运算符之间没有明确的区别。

```nim
func `++`(x: var int; y: int = 1; z: int = 0) =
  x = x + y + z

var g = 70
++g
g ++ 7
# 反引号中的运算符被视为一个函数 'f':
g.`++`(10, 20)
echo g  # writes 108
```



* 运算符只是函数的语法糖。
* 当定义函数时，运算符标记位于反记号（例如 `++` ）内，并且可以使用反记号符号将其作为函数调用。

回想一下，`var` 关键字表示可变性：

* 除非声明为`var` ，否则参数为只读
* `var` 表示 "通过引用传递"（它被实现为隐藏的指针）。



### 语句与表达式

语句需要缩进：


```nim
# 单个赋值语句不需要缩进：
if x: x = false

# 嵌套if语句需要缩进：
if x:
  if y:
    y = false
else:
  y = true

# 需要缩进，因为有两个语句
# 遵循以下条件：
if x:
  x = false
  y = false
```


您也可以使用分号代替换行符，但这在 Nim 很少见。

表达式并非真正基于缩进，因此您可以在表达式中使用额外的空格：


```nim
if thisIsaLongCondition() and
    thisIsAnotherLongCondition(1,
        2, 3, 4):
  x = true
```



这对于拆分长行非常方便。

根据经验，可以在运算符、括号和逗号之后添加可选的缩进。

最后，`if`, `case` 等语句也可以作为表达式使用，因此它们可以生成值。

作为结束本节的简单示例，
这里是一个完整的 Nim 程序，可以显示更多的语法。
如果您熟悉 Python ，这应该很容易理解：


```nim
func indexOf(s: string; x: set[char]): int =
  for i in 0..<s.len:
    if s[i] in x: return i
  return -1

let whitespacePos = indexOf("abc def", {' ', '\t'})
echo whitespacePos
```



* Nim使用静态类型，因此参数具有类型：名为 `s` 的输入参数具有类型 `string` ；
`x` 具有 "字符数组 set[char]" 类型；名为 `indexOf` 的函数生成一个整数值作为最终结果。
* 您可以通过 `for` 循环对字符串索引进行迭代，目标是找到字符串中第一个字符与给定值集匹配的位置。

* 在调用函数时，我们使用花括号 (`{}`) 构造一组覆盖 `空白` 属性的字符。




到目前为止，我们主要讨论了语法，这里的重点是我们的第一条禅法则：

> 简洁的代码与可读性并不冲突，它可以提高可读性。

正如你在上面的小例子中看到的，它很容易理解，因为我们基本上忽略了符号
它们没有什么意义，例如用于块的大括号或用于终止语句的分号。

这会扩大规模，因此在较长的程序中，当您需要查看的代码较少时，这会非常有用，因为这样您可以更容易地了解代码该如何工作或它可以做什么（而不需要获得太多细节）。



通常情况下，参数是这样的："语法很简洁，因此不可读，您所要做的就是保存输入工作"；在我看来，这完全没有抓住重点，这不是为了节省击键或打字工作量，当您**查看**生成的代码时，这可以节省精力。程序的阅读频率比编写的频率高，当你阅读它们时，如果它们更短，那真的很有帮助。



## 智能的编译器

Nim之禅的第二条规则是：

>编译器必须能够推理代码。

这意味着我们希望：
- 结构化编程。
- 静态类型！
- 静态绑定！
- 副作用追踪。
- 异常跟踪。
- 可变限制（共享的可变状态是敌人，但如果不共享状态，则可以对其进行转换：我们希望能够精确地做到这一点）。
- 基于值的数据类型（别名很难解释，除了ref，基本都是值类型）。

现在我们将详细了解这些要点的含义。



### 结构化编程

在下面的示例中，任务是对文件中的所有单词进行计数（由 `filename` 作为 `string` 给出），并生成一个字符串计数表，最后得到每个单词的条目以及它在文本中出现的次数。

```nim
import tables, strutils

proc countWords(filename: string): CountTable[string] =
  ## Counts all the words in the file.
  result = initCountTable[string]()
  for word in readFile(filename).split:
    result.inc word
  # 'result' instead of 'return', no unstructed control flow
```



幸运的是，Nim 标准库已经提供了一个 `CountTable`，因此 `proc` 的第一行是新的计数表。
 `result`  内置于 Nim 中，它表示返回值，因此您不必编写非结构化编程的 `return result` ，因为 `return` 立即离开每个范围并返回结果。 Nim 确实提供了 `return` 语句，但我们建议您不要使用它，因为这是非结构化编程。



在 `proc` 的其余部分中，我们将文件读入单个缓冲区，将其拆分为单个单词，然后通过 `result.inc` 计算单词数。

结构化编程意味着代码块只有一个入口点和一个出口点。

在下一个示例中，我以更复杂的方式使用 `continue` 语句离开 `for` 循环体：



```nim
for item in collection:
  if item.isBad: continue
  # what do we know here at this point?
  use item
```

* 对于此集合中的每个项目，如果项目不好将继续循环，否则将使用该项目。
* 在 `continue` 语句之后我知道什么？我知道这个项目不错。

为什么不这样写呢？使用结构化编程：



```nim
for item in collection:
  if not item.isBad:
    # what do we know here at this point?
    # that the item is not bad.
    use item
```
* 这里的缩进使用了代码中的固定值，这样我们可以更容易地看明白，当我  `使用项目` 时，固定值认为该项目不坏。



如果您喜欢用 `continue` 和 `return` 语句，也可以，使用它们并不犯错。如果其他方法都不起作用，我自己也会使用它们，但您应该尽量避免使用。更重要的是，这意味着我们可能永远不会在 Nim 编程语言中添加更通用的 `go to` 语句，因为 `go to` 更不符合结构化编程范式。

我们希望处于这样的位置，可以展示代码越来越多的属性，结构化编程可以帮助实现这一点。



### 静态类型

静态类型的观点是，希望您使用问题域的自定义专用类型。

这里我们有一个小例子，展示了"不重复字符串" `distinct string` 特性（带有 `enum` 和 `set`）：

```nim
type
  SandboxFlag = enum         ## what the interpreter should allow
    allowCast,               ## allow unsafe language feature: 'cast'
    allowFFI,                ## allow the FFI
    allowInfiniteLoops       ## allow endless loops

  NimCode = distinct string

proc runNimCode(code: NimCode; flags: set[SandboxFlag] = {allowCast, allowFFI}) =
  ...
```




* `NimCode` 可以存储为 `string` ，但它是一个不同的字符串 `distinct string` ，因此它是一种具有特殊规则的特殊类型。

* `proc runNimCode` 可以运行传递给它的任意 Nim 代码，但它是一个可以运行代码的虚拟机，它可以限制可能的操作。



* 本例中有一个沙盒环境，您可能想使用一些自定义属性。例如，您可以说：允许 Nim `cast` 操作  (`allowCast`)  或允许外部函数接口 (`allowFFI`) ；最后一个选项是允许 Nim 代码运行到无限循环中 (`allowInfiniteLoops`)。

* 我们将选项放在一个普通的 `enum` 中，然后我们就可以生成一组 `set` 枚举，表示每个选项是独立的。



例如，如果将上述内容与 C 进行比较，在 C 中使用相同的机制是常见的，但会失去类型安全性：

```c
#define allowCast (1 << 0)
#define allowFFI (1 << 1)
#define allowInfiniteLoops (1 << 2)

void runNimCode(char* code, unsigned int flags = allowCast|allowFFI);

runNimCode("4+5", 700); // nobody stops us from passing 700
```




* 当调用 `runNimCode` 时，`flags` 只是一个无符号整数，没有人阻止您传递值700，即使它没有任何意义。

* 您需要使用位运算来定义 `allowCast`，... `allowInfiniteLoops`。

你在这里失去了信息：尽管程序员的头脑中非常清楚这个 `flags`  参数的真正有效值是什么，但它并没有写在程序中，所以编译器不能帮助你。



### 静态绑定

我们希望 Nim 使用静态绑定。下面是一个经过修改的 `hello world` 示例：

```nim
echo "hello ", "world", 99
```

这样编译器会将状态重写为：

```nim
echo([$"hello ", $"world", $99])
```



- `echo` 声明为：``proc echo(a: varargs[string, `$`]);``
- `$` （Nim 的 `toString` 运算符）应用于每个参数。
- 我们使用重载（在本例中为 `$` 运算符）而不是动态绑定（例如在 C# 中使用的）。



该机制是可扩展的：

```nim
proc `$`(x: MyObject): string = x.s
var obj = MyObject(s: "xyz")
echo obj  # works
```




* 在这里，一个自定义类型 `MyObject` ，定义了 `$` 运算符，实际上只返回 `s` 字段。
* 然后，构造一个值为 `"xyz"` 的 `MyObject` 。
* `echo` 了解如何打印类型为 `MyObject` 的对象，因为它们定义了一个 `$` 运算符。



### 基于值的数据类型

我们需要基于值的数据类型，以便程序更容易推理。

我说过要限制可变的状态共享。

函数式编程语言通常忽略的一个解决方案是，为了做到这一点，您需要限制别名，而不是转换。

转换非常直接、方便和有效。



```nim
type
  Rect = object
    x, y, w, h: int

# construction:
let r = Rect(x: 12, y: 22, w: 40, h: 80)

# field access:
echo r.x, " ", r.y

# assignment does copy:
# 赋值语句执行了复制，object是个值类型。
var other = r
other.x = 10
assert r.x == 12
```

赋值语句 `other = r` 执行了一个复制，这意味着在这里没有涉及到远处的恐怖动作（不是引用地址的改变），只有一条到 `r.x` 的访问路径，而 `other.x` 是到另一存储位置的访问路径。



### 副作用追踪

我们希望能够追踪副作用。

下面是一个示例，目标是计算字符串中的子字符串数。


```nim
import strutils

proc count(s: string, sub: string): int {.noSideEffect.} =
  result = 0
  var i = 0
  while true:
    i = s.find(sub, i)
    if i < 0: break
    echo "i is: ", i  # error: 'echo' can have side effects
    i += sub.len
    inc result
```



让我们假设这是错误的代码，并且存在调试 `echo` 语句。
编译器会抱怨：你说过程没有副作用，但 `echo` 会产生副作用，所以去修复代码吧！

>副作用：是否修改其他的全局变量，是副作用的一个考量。



另一个方面,虽然 Nim 编译器非常聪明，可以帮助您，但你仍需要做些工作，覆盖这些好的默认值。



所以如果我说："好吧，我知道这会产生副作用，但我不在乎，因为这是我为调试添加的唯一代码，你可以说： "嘿，将这段代码转换为 `noSideEffect` 效果" ，然后编译器很高兴，并说"好，继续" ：


```nim
import strutils

proc count(s: string, sub: string): int {.noSideEffect.} =
  result = 0
  var i = 0
  while true:
    i = s.find(sub, i)
    if i < 0: break
    {.cast(noSideEffect).}:
      echo "i is: ", i  # 'cast', so go ahead
    i += sub.len
    inc result
```




`cast` 的意思是： "我知道我在做什么，别管我" 。

### 异常跟踪

我们需要异常跟踪！

这里是我的 `main proc` ，我想说它不会引发任何问题，我希望能确保处理了可能发生的每个异常：




```nim
import os

proc main() {.raises: [].} =
  copyDir("from", "to")
  # Error: copyDir("from", "to") can raise an
  # unlisted exception: ref OSError
```
编译器会抱怨说  "看，这是错误的，`copyDir` 可以引发未列出的异常，即`OSError`" 。

所以你说， "好吧，事实上我没有处理"，所以现在我可以说 `main` 引发 `OSError`，编译器说： "你说得对！" ：


```nim
import os

proc main() {.raises: [OSError].} =
  copyDir("from", "to")
  # compiles :-)
```

我们希望能够对此进行一点参数化：

```nim
proc x[E]() {.raises: [E].} =
  raise newException(E, "text here")

try:
  x[ValueError]()
except ValueError:
  echo "good"
```




- 我有一个泛型 `proc x[E]`（`E`是泛型类型），我说： `无论你传递给这个`x`的`E`，这就是我要提出的。

- 然后我用这个 `ValueError` 异常实例化这个 `x` ，编译器很高兴！

我真的很惊讶，这是开箱即用的。

当我提出这个例子时，我很确定编译器会产生一个 bug ，但它已经很好地处理了这种情况，我认为原因是其他人帮助解决了这个 bug。


### 不变性限制

在这里，我将展示并解释的实验性 `strictFuncs` 严格函数开关的作用：

```nim
{.experimental: "strictFuncs".}

type
  Node = ref object
    next, prev: Node
    data: string

func len(n: Node): int =
  var it = n
  result = 0
  while it != nil:
    inc result
    it = it.next
```




- 有一个 `Node` 类型，它是一个 `ref object` ，`next` 和 `prev` 是指向这类对象的指针（这是一个双重链接列表）。还有一个类型为 `string` 的 `data` 字段。
- 有一个函数 `len` ，它计算链接列表中的节点数。

- 实现非常简单：除非它是 `nil` ，否则计算节点数，然后转到 `next` 节点。



关键的一点是，通过 `strictFuncs` ，我们告诉编译器参数现在是**深度**不可变的，
因此编译器可以使用此代码，也可以使用以下示例：

```nim
{.experimental: "strictFuncs".}

func insert(x: var seq[Node]; y: Node) =
  let L = x.len
  x.setLen L + 1
  x[L] = y
```



- 我想 `insert` 一些东西，但它是一个`func` ，所以它对我的可变性控制非常严格。
- 我想附加到 `x` ，这是一个节点序列，因此 `x` 通过 `var` 关键字**显式**可变（而 `y` 不可变）。
- 我可以将 `x` 的长度设置为旧长度加 1 ，然后覆盖其中的内容，这很好。

最后，我仍然可以改变本地状态：



```nim
func doesCompile(n: Node) =
  var m = Node()
  m.data = "abc"
```

我有一个类型为 `Node` 的变量 `m` ，但它是新创建的，然后我对它进行改变设置 `data` 字段，因为它没有连接到 `n` ，所以编译器很高兴。

其语义是："除非这些参数被明确标记为 `var`，否则不能改变通过参数的内容"。

下面是一个示例，编译器说：

"是的，听着，不，你正在尝试改变 `n`  ，但你处于 `strictFunc` 模式，因此不允许你这样做"



```nim
{.experimental: "strictFuncs".}

func doesNotCompile(n: Node) =
  n.data = "abc"
```

我们现在可以玩这些游戏，看看编译器有多聪明。

在这里，我试图欺骗编译器接受代码，但我无法：



```nim
{.experimental: "strictFuncs".}

func select(a, b: Node): Node = b

func mutate(n: Node) =
  var it = n
  let x = it
  let y = x
  let z = y # <-- is the statement that connected
            # the mutation to the parameter

  select(x, z).data = "tricky" # <-- the mutation is here
  # Error: an object reachable from 'n'
  # is potentially mutated
```



-  `select` 是一个助手函数，它接受两个节点，并简单地返回第二个节点。
- 然后我想改变 `n` ，但我把它分配给`it`，然后`it`分配给 `x`， `x`分配给`y`，`y`分配给了`z`。
- 然后选择 `x` 或 `z` ，然后对 `data` 字段进行改变，并将字符串覆盖为值 `tricky` 。



编译器将告诉您"错误，从 `n` 可访问的对象可能发生了改变"，并指出将构建图指向到此参数的语句。
它在内部所做的是：它有一个抽象图的概念，它以"构建的每个图都是不相交的"开始，但取决于函数的主体，这些不相交的图可以连接起来。

当你对某个东西进行改变时，图形就会发生改变，如果它与输入参数相连，那么编译器就会给出提示。



因此，第二条规则是：

>如果编译器不能推理代码，程序员也不能推理。

我们真的需要一个智能编译器来帮助你，因为编程非常困难。

## 元编程功能

另一条现在很有名的规则是：




>抄袭糟糕的设计不是好设计。

如果你说"嘿，X语言有F功能，我们也有吧！"，你复制了这个设计，但你不知道它是好是坏，因为你没有从第一原则开始。



所以，"C++有编译时函数求值，让我们也这样做吧！"。这不是添加编译时函数求值的原因，我们拥有它的原因（我们的做法与C++非常不同），
如下："我们有很多功能 F 的用例"。



在这种情况下，F 是宏系统：

"我们需要能够进行锁定、日志记录、延迟计算，一种类型安全的 `writeln/printf`，一种声明性的 UI 描述语言，异步和并行编程！因此，与其将这些特性构建到语言中，不如使用一个宏系统。"



让我们来看看这些元编程特性。
Nim 为此提供了**模板**和**宏**。

### 延迟计算模板

模板是一种简单的替换机制。

这里我定义了一个名为 `log` 的模板：

```nim
template log(msg: string) =
  if debug:
    echo msg

log("x: " & $x & ", y: " & $y)
```




您可以将其理解为某种函数，但关键的区别在于它直接在行中扩展代码（在那里调用 `log` ）。
您可以将上述代码与以下C代码进行比较，其中 `log` 是 `#define` ：

```c
#define log(msg) \
  if (debug) { \
    print(msg); \
  }

log("x: " + x.toString() + ", y: " + y.toString());
```



这很相似！这是一个模板（或 `#define` ）的原因是我们希望这个消息参数被延迟求值，因为在这个示例中，我确实执行了昂贵的操作，如字符串连接和将变量转换为字符串，如果禁用 `debug` ，则不应运行此代码。

通常的参数传递语义是："计算此表达式，然后调用函数" ，但在函数内部，您会注意到调试被禁用，您不需要所有这些信息，因此根本不必计算。
这就是这个模板在这里为我们实现的，因为它在调用时直接展开：

如果 `debug` 为false，则根本不执行这种复杂的凹面表达式。




### 控制流程的抽象模板：

我们可以将模板用于控制流程的抽象。如果我们想要一个 `withLock` 语句，C# 提供了它是一个语言原语，在 Nim 中，您根本不必将其构建到语言中，只需编写一个 `withLock` 模板，即可获取 `lock` ：

```nim
template withLock(lock, body) =
  var lock: Lock
  try:
    acquire lock
    body
  finally:
    release lock

withLock myLock:
  accessProtectedResource()
```



-  `withLock` 获取锁并最终释放锁。
- 在锁定部分之间运行的代码，可以通过冒号缩进语法将其传递给 `withLock` 语句。

### 用于实现 DSL 的宏

您可以使用宏来实现 DSL（领域特定语言）。

下面是描述html代码的DSL：

```nim
html mainPage:
  head:
    title "Zen of Nim"
  body:
    ul:
      li "A bunch of rules that make no sense."

echo mainPage()
```








### 函数提升

您可以将元编程用于编程中反复出现的 "提升" 操作。

例如，我们在 `数学` 中对浮点数进行了平方根运算，现在我想对一系列浮点数进行平方根运算。

我可以使用 `map` 调用，但也可以创建专用的 `sqrt` 函数：



```nim
import math

template liftFromScalar(fname) =
  proc fname[T](x: openArray[T]): seq[T] =
    result = newSeq[typeof(x[0])](x.len)
    for i in 0..<x.len:
      result[i] = fname(x[i])

# make sqrt() work for sequences:
liftFromScalar(sqrt)
echo sqrt(@[4.0, 16.0, 25.0, 36.0])
# => @[2.0, 4.0, 5.0, 6.0]
```



- 我们将 `fname` 传递给模板，并将 `fnname` 应用于序列的每个元素。
-  `proc` 的最终名称也是 `fname` （在本例中为 `sqrt` ）。



### 声明式编程  

您可以使用模板将命令性代码转换为声明性代码。

这里有一个从我们的测试套件中提取的示例：

```nim
proc threadTests(r: var Results, cat: Category,
                  options: string) =
  template test(filename: untyped) =
    testSpec r, makeTest("tests/threads" / filename,
      options, cat, actionRun)
    testSpec r, makeTest("tests/threads" / filename,
      options & " -d:release", cat, actionRun)
    testSpec r, makeTest("tests/threads" / filename,
      options & " --tlsEmulation:on", cat, actionRun)

  test "tactors"
  test "tactors2"
  test "threadex"
```



有名为 `tactors` 、 `tactors2` 和 `threadex` 的线程测试，这些测试中的每一个都以三种不同的配置运行：默认选项、默认选项加释放开关、默认选项和线程本地存储仿真。

这个 `threadTests` 调用需要很多参数（如类别、选项和文件名），当你一遍又一遍地复制和粘贴它时，这会分散你的注意力，所以这里我们想说 "我有一个叫做 `tactors` 的测试，我有一项叫做 `tactors2` 的测试并且我有一项名为 `threadex` 的测试" ，通过缩短这个测试，您现在可以在您实际想要处理的抽象级别上工作：



```nim
test "tactors"
test "tactors2"
test "threadex"
```

您可以进一步缩短这个时间，因为所有这些测试调用都有点烦人。
我真正想说的是：



```nim
test "tactors", "tactors2", "threadex"
```

下面是一个简单的宏，它可以做到这一点：


```nim
import macros

macro apply(caller: untyped;
            args: varargs[untyped]): untyped =
  result = newStmtList()
  for a in args:
    result.add(newCall(caller, a))

apply test, "tactors", "tactors2", "threadex"
```



因为它很简单，所以无法完成全部任务，您需要说"应用测试" 。
这个宏生成一个语句列表，列表中的每个语句实际上都是一个调用表达式，用 `a` 调用这个 `test` （ `a` 是当前参数，我们遍历每个参数）。




细节并没有那么重要，这里的关键见解是 Nim 给了你做这些事情的能力，一旦你习惯了，这就非常容易了。

### 类型安全 Writeln/Printf

下一个示例是一个宏系统，它为我们提供了类型安全的 `printf` ：



```nim
proc write(f: File; a: int) = echo a
proc write(f: File; a: bool) = echo a
proc write(f: File; a: float) = echo a

proc writeNewline(f: File) =
  echo "\n"

macro writeln*(f: File; args: varargs[typed]) =
  result = newStmtList()
  for a in args:
    result.add newCall(bindSym"write", f, a)
  result.add newCall(bindSym"writeNewline", f)
```



- 与之前一样，我们在宏的第一行创建一个语句列表，然后迭代每个参数，生成一个名为 `write` 的函数调用。
- `bindSym `write` `绑定`write`，但这不是一个单独的`write`操作，这是一个重载操作，因为我在示例开头有三个`write`（用于`int`、`bool`和`float`），重载解析开始并选择正确的 `write` 操作。
- 最后，在宏的最后一行，有一个对前面声明的 `writeNewline` 函数的调用（它生成一个新行）。



## 实用的语言

编译器很聪明，但：

> 不要妨碍程序员

我们有大量用 C++、C 和 Javascript 编写的代码，程序员确实需要重用这些代码。
通过将 Nim 编译为 C++、C 和 JavaScript ，我们实现了这种 **互操作性**。
请注意，这是为了实现互操作性，其理念不是：

"让我们使用C++和Nim，因为 Nim 没有提供完成任务所需的一些功能"。

Nim确实提供了低级功能，例如：



* 位运算，
* 不安全的类型转换（"cast"），
* 原始指针。

与 C++ 接口是最后的手段，通常我们希望你编写 Nim 代码而不是离开 Nim 代码，但现实世界会介入并说：
"嘿，有很多代码已经用这些语言编写了，你如何让这些系统的互操作性变得非常好"。



我们不希望 Nim 只是众多语言中的一种，然后您使用不同的编程语言来完成您的系统。理想情况下，您只使用 Nim 语言，因为这样做要便宜得多。
然后你可以雇佣只懂一种编程语言而不懂四种编程语言（或者你需要的任何语言）的程序员。
互操作性的故事发展到现在，我们实际上提供了一个 `emit` 语句，您可以直接将外来代码放入 Nim 代码中，编译器将这两样东西合并到最终文件中。



例如：

```nim
{.emit: """
static int cvariable = 420;
""".}

proc embedsC() =
  var nimVar = 89
  {.emit: ["""fprintf(stdout, "%d\n", cvariable + (int)""",
    nimVar, ");"].}

embedsC()
```



您可以注入一个 `static int cvariable` ，通信是双向的，因此您可以注入 `fprintf` 语句，其中变量 `nimVar` 实际上来自 Nim（使用括号表示法，您可以在同一环境中同时使用字符串和名称表达式）。

C 代码可以使用 Nim 代码，反之亦然。

然而，这确实不是一种很好的接口方式，这只是为了表明我们希望你能够完成任务。



一个更好的互操作性方法是，你可以告诉Nim："嘿，有一个 `fprintf` 函数，它来自 C ，这些是它的类型，我希望能够调用它"。
尽管如此， `emit`  编译指示很好地表达了**我们希望这种语言是实用的**这一点。



## 可定制的内存管理

现在是另一个话题，到目前为止，我们还没有讨论内存管理。
在较新的 Nim 版本中，它基于析构函数，称为 `gc:arc` 或 `gc:orc` 模式。

析构函数和所有权是 C++ 和 Rust 中熟悉的概念。




此处的 `sink` 参数表示函数获得字符串的所有权（然后它对 `x` 没有任何作用）：

```nim
func f(x: sink string) =
  discard "do nothing"

f "abc"
```



问题是："我是否产生了内存泄漏？发生了什么？"。

您可以询问Nim编译器：
"嘿，为我展开这个函数 `f`；告诉我析构函数在哪里，在哪里执行移动，执行深度复制的位置"（使用 `nim c --gc:orc --expandArc:f $file` 编译）。



编译器会告诉您"看，函数`f`实际上是您的丢弃语句，我在末尾向析构函数添加了这个调用"：

```nim
func f(x: sink string) =
  discard "do nothing"
 `=destroy`(x)
```

好的是，**Nim 的中间语言是 Nim 本身**，
所以 Nim 是一种可以很好地表达一切的语言。



还有个不同的例子：

```nim
var g: string

proc f(x: sink string) =
  g = x

f "abc"
```



这一次我获得了 `x` 的所有权，我真的对所有权做了一些事情，
即我将 `x` 放入这个全局变量 `g` 中。
同样，我们可以问编译器它做什么，编译器说：
"这是一个移动操作，称为 `=sink` "。
因此，我们将 `x` 移动到 `g` 中，这一移动负责释放 `g` 内部的内容（如果有），然后将 `x` 的值转换为：



```nim
var g: string

proc f(x: sink string) =
 `=sink`(g, x)

f "abc"
```

它真正做了什么，不幸的是，这里没有真正看到，它说："好吧，`x` 被移动到 `g` 中，然后我们说 `x` 移动并调用析构函数"，但这些`wasMoved` 和 `=destroy` 调用取消了，所以编译器为我们优化了这一点：



```nim
var g: string

proc f(x: sink string) =
 `=sink`(g, x)
  # optimized out:
  wasMoved(x)
 `=destroy`(x)

f "abc"
```
### 自定义容器

您可以使用这些移动、析构函数和复制赋值来创建自定义数据结构。

这里我有一个简短的例子，不详细说明了。


**析构**:

```nim
type
  myseq*[T] = object
    len, cap: int
    data: ptr UncheckedArray[T]

proc `=destroy`*[T](x: var myseq[T]) =
  if x.data != nil:
    for i in 0..<x.len: `=destroy`(x[i])
    dealloc(x.data)
```



**移动操作**:

```nim
proc `=sink`*[T](a: var myseq[T]; b: myseq[T]) =
  # move assignment, optional.
  # Compiler is using `=destroy` and
  # `copyMem` when not provided
 `=destroy`(a)
  a.len = b.len
  a.cap = b.cap
  a.data = b.data
```



**赋值操作**:

```nim
proc `=copy`*[T](a: var myseq[T]; b: myseq[T]) =
  # do nothing for self-assignments:
  if a.data == b.data: return
 `=destroy`(a)
  a.len = b.len
  a.cap = b.cap
  if b.data != nil:
    a.data = cast[typeof(a.data)](alloc(a.cap * sizeof(T)))
    for i in 0..<a.len:
      a.data[i] = b.data[i]
```



**访问器**

```nim
proc add*[T](x: var myseq[T]; y: sink T) =
  if x.len >= x.cap: resize(x)
  x.data[x.len] = y
  inc x.len

proc `[]`*[T](x: myseq[T]; i: Natural): lent T =
  assert i < x.len
  x.data[i]

proc `[]=`*[T](x: var myseq[T]; i: Natural; y: sink T) =
  assert i < x.len
  x.data[i] = y
```

这里的重点是析构函数、移动运算符等，可以由您为自定义容器编写，
然后它们可以与 Nim 的内置容器配合使用，
但它也可以让您非常精确地控制内存分配以及如何分配。

因此，禅的另一条法则是：

>可定制的内存管理




## Nim 之禅

再次重复以下规则作为总结：

- **抄袭糟糕的设计不是好的设计**：我们希望通过从问题的第一原则出发来创建好的设计。
- **如果编译器不能推理代码，程序员也不能**。
- 然而，**不要妨碍程序员**。编译器是一只聪明的狗：你可以教它新的技巧，它确实帮助你，它可以为你执行任务，比如拿报纸，但最终程序员还是比编译器聪明。
- 我们希望**将工作转移到编译时**，因为**程序的运行频率高于编译时**。


- 我们需要**可定制的内存管理**。
- **简洁的代码与可读性不冲突，它可以提高可读性**。
- 禅的这一规则就像**利用元编程来保持语言的小型化**，然而，当 Nim 真的提供了相当多的功能时，很难做到这一点，也很难保持严肃的态度。
"我们希望语言完整"和"我们希望最小"之间存在冲突。 Nim 越老， Nim 就越注重完整性（所有最小的语言都是为了满足某些需求而发展的）。
- **优化是专业化**。我还没有谈到这一点，但**当您需要更高的速度**时，您应该真正考虑**编写自定义代码**。Nim 标准库不能为每个人提供所有的东西，对我们来说，为所有的东西提供最好的库也要困难得多，因为最好的库必须是通用的，它必须是最快的库，它必须具有最少的编译时间开销，这很难实现。"好吧，Nim将其作为标准库提供，但在这里，我自己用 10 行编写了这个库，我可以对它进行基准测试，通常我的自定义代码更快，因为它是根据我编写的应用程序手工定制的"。所以真正的问题是：专门化你的代码，然后它会运行得很快。



- 最后，**应该有一种而且只有一种编程语言来处理所有事情。那是 Nim 的语言**

感谢您的阅读！

