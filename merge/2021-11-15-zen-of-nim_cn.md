








# Nim 之禅

1. 拷贝不良设计不是好设计。
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
>在这里，我们在一开始就提供了Nim禅 的规则，为了便于参考，对其进行了编号。
>上述规则的讨论是在对语言进行一般性讨论的背景下进行的，没有按照上面的顺序。
>这里的内容是在原始演示之后呈现的，从幻灯片材料和视频记录开始，经过很少的编辑（这导致了非正式的基调）。
>



>目录：
> - 简介
> - 语法（引入Nim并激发规则6：简洁的代码可以提高可读性）
> - 智能编译器（规则2：编译器必须能够推理代码）
> - 元编程功能（通过规则1引入：复制不良设计…）
> - 实用语言（规则3：不要妨碍程序员）
> - 可定制内存管理（规则5）
> - Nim之禅（对所有规则进行回顾和讨论；规则4、7、8、9仅在此讨论）



## 简介

在这篇博文中，我将解释 Nim 语言的哲学，以及为什么 Nim 可以用于广泛的应用领域，例如：

- 科学计算
- 游戏
- 编译器
- 操作系统开发
- 编写脚本
- 其他一切



“禅”意味着我们将达成一套指导语言设计和进化的规则（如上所示），
下面将通过示例来了解这些规则。



## 语法

让我通过 Nim 的语法来介绍它。

我知道大多数人可能都知道这门语言，但为了给你们一个简单的介绍，我将解释基本语法，并希望得出有趣的结论。

Nim 使用基于 **缩进的语法** ，其灵感来自 Haskell 或 Python ，**适合 Nim 的宏系统**。




### Function 函数应用程序

Nim 区分语句和表达式，大多数表达式是函数应用程序（也称为“过程调用”）。

函数应用程序使用带括号的传统数学语法：`f()`, `f(a)`, `f(a, b)`。

这是语法糖：




|   |  语法糖     |   意思        |   例子         |
|---|------------|--------------|----------------|
| 1 |  `f a`     |   `f(a)`            |   `spawn log("some message")`  |
| 2 |  `f a, b`  |   `f(a, b)`         |   `echo "hello ", "world"`     |
| 3 |  `a.f()`   |   `f(a)`            |   `db.fetchRow()`              |
| 4 |  `a.f`     |   `f(a)`            |   `mystring.len`               |
| 5 |  `a.f(b)`  |   `f(a, b)`         |   `myarray.map(f)`             |
| 6 |  `a.f b`   |   `f(a, b)`         |   `db.fetchRow 1`              |
| 7 |  `f"\n"`   |   `f(r"\n")`        |   `re"\b[a-z*]\b"`             |
| 8 |  `f a: b`  |   `f(a, b)`         |   `lock x: echo "hi"`          |



* 在函数规则 1 和 2 中，可以省略括号，并提供一些示例，您可以了解为什么能这么用：
`spawn` 看起来像一个关键字，这很好，因为它做了一些特殊的事情；
`echo` 也以省略括号而闻名，因为通常这些语句是为了调试，可以快速完成任务。

* 有一个可用的点符号，可以省略括号（规则 3-6 ）。

* 规则 7 是关于字符串的：`f` 后面跟着一个没有空格的字符串仍然是一个调用，但字符串被转换为原始字符串，这对正则表达式非常方便，因为正则表达式有自己的反斜杠转义符。

* 在最后一条规则中，我们可以看到您可以使用“`:`”语法将**代码块**传递给 `f` 。
代码块通常是传递给函数的最后一个参数。这可用于创建自定义 `lock` 语句，类似的 `with`等其他的模板或者宏。

在您希望直接引用 `f` 的情况下，有 **一个例外**，即省略括号的 `f` 不表示 `f()` 。
对于  `myarray.map(f)` ，您不希望调用 `f` ，而是希望将 `f` 本身传递给 `map` 。




### Operators

Nim has binary and unary operators:

* Most of the time binary operators are simply invoked as `x @ y`
  and unary operators as `@x`.
* There is no explicit distinction between operators and functions, and between binary and unary operators.

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

* 在调用函数时，我们使用花括号 (`{}`) 构造一组覆盖“空白”属性的字符。




到目前为止，我们主要讨论了语法，这里的重点是我们的第一条禅法则：

> 简洁的代码与可读性并不冲突，它可以提高可读性。

正如你在上面的小例子中看到的，它很容易理解，因为我们基本上忽略了符号
它们没有什么意义，例如用于块的大括号或用于终止语句的分号。

这会扩大规模，因此在较长的程序中，当您需要查看的代码较少时，这会非常有用，因为这样您可以更容易地了解代码该如何工作或它可以做什么（而不需要获得太多细节）。



通常情况下，参数是这样的："语法很简洁，因此不可读，您所要做的就是保存输入工作"；在我看来，这完全没有抓住重点，这不是为了节省击键或打字工作量，当您**查看**生成的代码时，这可以节省精力。程序的阅读频率比编写的频率高，当你阅读它们时，如果它们更短，那真的很有帮助。



## 智能编译器

Nim之禅的第二条规则是：

>编译器必须能够推理代码。

这意味着我们希望：
- 结构化编程。
- 静态类型！
- 静态绑定！
- 副作用追踪。
- 异常跟踪。
- 可变限制（共享的可变状态是敌人，但如果不共享状态，则可以对其进行转换：我们希望能够精确地做到这一点）。
- 基于值的数据类型（别名很难解释！）。

现在我们将详细了解这些要点的含义。



### 结构化编程

在下面的示例中，任务是对文件中的所有单词进行计数（由 `filename` 作为  `string` 给出），并生成一个字符串计数表，最后得到每个单词的条目以及它在文本中出现的次数。

```nim
import tables, strutils

proc countWords(filename: string): CountTable[string] =
  ## Counts all the words in the file.
  result = initCountTable[string]()
  for word in readFile(filename).split:
    result.inc word
  # 'result' instead of 'return', no unstructed control flow
```



幸运的是，Nim 标准库已经提供了一个 `CountTable`，因此  `proc` 的第一行是新的计数表。
 `result`  内置于 Nim 中，它表示返回值，因此您不必编写非结构化编程的 `return result` ，因为  `return` 立即离开每个范围并返回结果。 Nim 确实提供了 `return` 语句，但我们建议您不要使用它，因为这是非结构化编程。



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
* 这里的缩进使用了代码中的固定值，这样我们可以更容易地看明白，当我 “使用项目”时，固定值认为该项目不坏。



如果您喜欢用 `continue` 和 `return` 语句，也可以，使用它们并不犯错。如果其他方法都不起作用，我自己也会使用它们，但您应该尽量避免使用。更重要的是，这意味着我们可能永远不会在 Nim 编程语言中添加更通用的 go to 语句，因为 go to 更不符合结构化编程范式。

我们希望处于这样的位置，可以展示代码越来越多的属性，结构化编程可以帮助实现这一点。



### 静态类型

静态类型的观点是，希望您使用问题域的自定义专用类型。

这里我们有一个小例子，展示了不同字符串 `distinct string` 特性（带有 `enum` 和 `set`）：

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




*  `NimCode` 可以存储为 `string` ，但它是一个不同的字符串 `distinct string` ，因此它是一种具有特殊规则的特殊类型。

*  `proc runNimCode` 可以运行传递给它的任意 Nim 代码，但它是一个可以运行代码的虚拟机，它可以限制可能的操作。



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

* 您需要使用位转换操作来定义 `allowCast`，... `allowInfiniteLoops`。

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
- `$` （Nim 的  `toString` 运算符）应用于每个参数。
- 我们使用重载（在本例中为 `$` 运算符）而不是动态绑定（例如在C#中）。



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

我说过要限制可变状态共享。

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
var other = r
other.x = 10
assert r.x == 12
```

赋值语句 `other = r` 执行了一个复制，这意味着在这里没有涉及到远处的恐怖动作，只有一条到 `r.x` 的访问路径，而 `other.x` 不是到同一存储器位置的访问路径。



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



另一个方面,虽然 Nim 编译器非常聪明，可以帮助您，但你仍需要做些工作，覆盖这些好的默认值。



所以如果我说：“好吧，我知道这会产生副作用，但我不在乎，因为这是我为调试添加的唯一代码，你可以说：“嘿，将这段代码转换为  `noSideEffect` 效果”，然后编译器很高兴，并说“好，继续”：


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




`cast` 的意思是：“我知道我在做什么，别管我”。

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
编译器会抱怨说 “看，这是错误的，`copyDir` 可以引发未列出的异常，即`OSError`”。

所以你说，“好吧，事实上我没有处理”，所以现在我可以说 `main` 引发 `OSError`，编译器说：“你说得对！”：


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




- 我有一个泛型 `proc x[E]`（`E`是泛型类型），我说：“无论你传递给这个`x`的`E`，这就是我要提出的。

- 然后我用这个 `ValueError` 异常实例化这个 `x` ，编译器很高兴！

我真的很惊讶，这是开箱即用的。

当我提出这个例子时，我很确定编译器会产生一个bug，但它已经很好地处理了这种情况，我认为原因是其他人帮助解决了这个bug。


### Mutability restrictions

Here I am going to show and explain what the experimental `strictFuncs` switch does:

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




- 有一个 `Node` 类型，它是一个 `ref object` ，`next` 和 `prev` 是指向这类对象的指针（这是一个双重链接列表）。还有一个类型为 `string` 的  `data` 字段。
- 有一个函数 `len` ，它计算链接列表中的节点数。

- 实现非常简单：除非它是 `nil` ，否则计算节点数，然后转到 `next` 节点。





































































































































































































