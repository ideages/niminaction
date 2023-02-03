{==+==}
---
title: "Zen of Nim"
author: "Andreas Rumpf (Araq), Pietro Peterlongo"
excerpt: "Transcript of Zen of Nim presentation at NimConf2021"
---
{==+==}



{==+==}

{==+==}
<div class="sidebarblock">
  <div class="content">
    <div class="paragraph">
      This is a transcript of Araq's presentation at NimConf2021 delivered on June 26th
      (see the video on <a href="https://www.youtube.com/watch?v=D_G9h7DcIqM&t=240s">youtube</a>,
      check the slides on <a href="https://github.com/Araq/nimconf2021">github</a>).
      It has been adapted to blog post format by <a href="https://github.com/pietroppeter">Pietro Peterlongo</a>
      and further reviewed by Araq.
    </div>
  </div>
</div>
{==+==}



{==+==}

{==+==}
# Zen of Nim

1. Copying bad design is not good design.
2. If the compiler cannot reason about the code, neither can the programmer.
3. Don't get in the programmer's way.
4. Move work to compile-time: Programs are run more often than they are compiled.
5. Customizable memory management.
6. Concise code is not in conflict with readability, it enables readability.
7. (Leverage meta programming to keep the language small.)
8. Optimization is specialization: When you need more speed, write custom code.
9. There should be one and only one programming language for everything. That language is Nim.
{==+==}

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

{==+==}

{==+==}
> **Editor's note:**
>
> In the original presentation the Zen of Nim was given at the end (and without numbering).
> Here we provide the Zen of Nim rules at the very beginning, numbered for ease of referencing.
> The discussion of the above rules is done in the context of a general discussion of the language
> and does not try to follow the order above.
> The content is here presented following the original presentation,
> starting from slide material and transcript of the video with minimal editing
> (this results in an informal tone).
>
{==+==}

>**编者按：**
>
>在最初的演示中，Nim 之禅在结尾处给出（没有编号）。
>在这里，我们在一开始就提供了Nim禅 的规则，为了便于参考，对其进行了编号。
>上述规则的讨论是在对语言进行一般性讨论的背景下进行的，没有按照上面的顺序。
>这里的内容是在原始演示之后呈现的，从幻灯片材料和视频记录开始，经过很少的编辑（这导致了非正式的基调）。
>

{==+==}

{==+==}
> Table of contents:
> - Introduction
> - Syntax (introduces Nim and motivates rule 6: concise code enables readability)
> - A smart compiler (rule 2: compilers must be able to reason about code)
> - Meta programming features (introduced through rule 1: copying bad design ...)
> - A practical language (rule 3: don't get in programmer's way)
> - Customizable memory management (rule 5)
> - Zen of Nim (recap and discussion of all the rules; rules 4, 7, 8, 9 are only discussed here)
{==+==}

>目录：
> - 简介
> - 语法（引入Nim并激发规则6：简洁的代码可以提高可读性）
> - 智能编译器（规则2：编译器必须能够推理代码）
> - 元编程功能（通过规则1引入：复制不良设计…）
> - 实用语言（规则3：不要妨碍程序员）
> - 可定制内存管理（规则5）
> - Nim之禅（对所有规则进行回顾和讨论；规则4、7、8、9仅在此讨论）

{==+==}

{==+==}
## Introduction

In this blog post I will explain the philosophy of Nim language and why Nim can be useful for a wide range of application domains, such as:

- scientific computing
- games
- compilers
- operating systems development
- scripting
- everything else
{==+==}

## 简介

在这篇博文中，我将解释 Nim 语言的哲学，以及为什么 Nim 可以用于广泛的应用领域，例如：

- 科学计算
- 游戏
- 编译器
- 操作系统开发
- 编写脚本
- 其他一切

{==+==}

{==+==}
"Zen" means that we will arrive at a set of rules (shown above) that guide the language design and evolution,
but I will go through these rules via examples.
{==+==}

“禅”意味着我们将达成一套指导语言设计和进化的规则（如上所示），
下面将通过示例来了解这些规则。

{==+==}

{==+==}
## Syntax

Let me introduce Nim via its syntax.
I am aware that most of you probably know the language, but to give you a gentle introduction even if you have not seen it before,
I will explain basic syntax and hopefully come to interesting conclusions.

Nim uses an **indentation based syntax** as inspired by Haskell or Python that **fits Nim's macro system**.
{==+==}

## 语法

让我通过 Nim 的语法来介绍它。

我知道大多数人可能都知道这门语言，但为了给你们一个简单的介绍，我将解释基本语法，并希望得出有趣的结论。

Nim 使用基于 **缩进的语法** ，其灵感来自 Haskell 或 Python ，**适合 Nim 的宏系统**。


{==+==}

{==+==}

### Function application

Nim distinguishes between statements and expressions and most of the time an expression is a function application (also called a "procedure call").
Function application uses the traditional mathy syntax with the parentheses: `f()`, `f(a)`, `f(a, b)`.

And here is the sugar:
{==+==}

### Function 函数应用程序

Nim 区分语句和表达式，大多数表达式是函数应用程序（也称为“过程调用”）。

函数应用程序使用带括号的传统数学语法：`f()`, `f(a)`, `f(a, b)`。

这是语法糖：


{==+==}

{==+==}
|   |  Sugar     |   Meaning           |   Example                      |
|---|------------|---------------------|--------------------------------|
| 1 |  `f a`     |   `f(a)`            |   `spawn log("some message")`  |
| 2 |  `f a, b`  |   `f(a, b)`         |   `echo "hello ", "world"`     |
| 3 |  `a.f()`   |   `f(a)`            |   `db.fetchRow()`              |
| 4 |  `a.f`     |   `f(a)`            |   `mystring.len`               |
| 5 |  `a.f(b)`  |   `f(a, b)`         |   `myarray.map(f)`             |
| 6 |  `a.f b`   |   `f(a, b)`         |   `db.fetchRow 1`              |
| 7 |  `f"\n"`   |   `f(r"\n")`        |   `re"\b[a-z*]\b"`             |
| 8 |  `f a: b`  |   `f(a, b)`         |   `lock x: echo "hi"`          |

{==+==}

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

{==+==}

{==+==}
* In rules 1 and 2 you can leave out the parentheses and there are examples so that you can see why that might be useful:
  `spawn` looks like a keyword, which is good, since it does something special;
  `echo` is also famous for leaving out the parentheses because usually you write these statements for debugging, thus you are in a hurry to get things done.
* You have a dot notation available and you can leave out parentheses (rules 3-6).
* Rule 7 is about string literals: `f` followed by a string without whitespace is still a call but the string is turned into a raw string literal,
  which is very handy for regular expressions because regular expressions have their own idea of what a backslash is supposed to mean.
* Finally, in the last rule we can see that you can pass a block of code to the `f` with a `:` syntax.
  The code block is usually the last argument you pass to the function. This can be used to create a custom `lock` statement.

There is **one exception** to leaving out the parentheses, in the case you want to refer to `f` directly: `f` does not mean `f()`.
In the case of `myarray.map(f)` you do not want to invoke `f`, instead you want to pass the `f` itself to `map`.
{==+==}

* 在函数规则 1 和 2 中，可以省略括号，并提供一些示例，您可以了解为什么能这么用：
`spawn` 看起来像一个关键字，这很好，因为它做了一些特殊的事情；
`echo` 也以省略括号而闻名，因为通常这些语句是为了调试，可以快速完成任务。

* 有一个可用的点符号，可以省略括号（规则 3-6 ）。

* 规则 7 是关于字符串的：`f` 后面跟着一个没有空格的字符串仍然是一个调用，但字符串被转换为原始字符串，这对正则表达式非常方便，因为正则表达式有自己的反斜杠转义符。

* 在最后一条规则中，我们可以看到您可以使用“`:`”语法将**代码块**传递给 `f` 。
代码块通常是传递给函数的最后一个参数。这可用于创建自定义 `lock` 语句，类似的 `with`等其他的模板或者宏。

在您希望直接引用 `f` 的情况下，有 **一个例外**，即省略括号的 `f` 不表示 `f()` 。
对于  `myarray.map(f)` ，您不希望调用 `f` ，而是希望将 `f` 本身传递给 `map` 。


{==+==}

{==+==}
### Operators

Nim has binary and unary operators:

* Most of the time binary operators are simply invoked as `x @ y`
  and unary operators as `@x`.
* There is no explicit distinction between operators and functions, and between binary and unary operators.

```nim
func `++`(x: var int; y: int = 1; z: int = 0) =
  x = x + y + z

var g = 70
++g
g ++ 7
# operator in backticks is treated like an 'f':
g.`++`(10, 20)
echo g  # writes 108
```
{==+==}

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

{==+==}

{==+==}
* Operators are simply sugar for functions.
* The operator token goes inside backticks (e.g. `++`) when the function is defined and it can be called as a function using backticks notation.
  
Recall that the `var` keyword indicates mutability:

* parameters are readonly unless declared as `var`
* `var` means "pass by reference" (it is implemented as a hidden pointer).
{==+==}

* 运算符只是函数的语法糖。
* 当定义函数时，运算符标记位于反记号（例如 `++` ）内，并且可以使用反记号符号将其作为函数调用。

回想一下，`var` 关键字表示可变性：

* 除非声明为`var` ，否则参数为只读
* `var` 表示 "通过引用传递"（它被实现为隐藏的指针）。

{==+==}

{==+==}
### Statements vs expressions

Statements require indentation:

```nim
# no indentation is needed for a single assignment statement:
if x: x = false

# indentation is needed for nested if statements:
if x:
  if y:
    y = false
else:
  y = true

# indentation is needed, because two statements
# follow the condition:
if x:
  x = false
  y = false
```
{==+==}

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

{==+==}

{==+==}
You can also use semicolons instead of new lines but this is very uncommon in Nim.

Expressions are not really based on indentation so you are free to use additional white space within expressions:

```nim
if thisIsaLongCondition() and
    thisIsAnotherLongCondition(1,
        2, 3, 4):
  x = true
```
{==+==}
您也可以使用分号代替换行符，但这在 Nim 很少见。

表达式并非真正基于缩进，因此您可以在表达式中使用额外的空格：


```nim
if thisIsaLongCondition() and
    thisIsAnotherLongCondition(1,
        2, 3, 4):
  x = true
```

{==+==}

{==+==}
This can be very handy for breaking up long lines.
As a rule of thumb you can have optional indentation after operators, parentheses and commas.

Finally the `if`, `case`, etc statements are also available as expressions, so they can produce a value.

As a simple example to conclude this section,
here is a full Nim program to show a little bit more of syntax.
If you are familiar with Python, this should be straightforward to read:

```nim
func indexOf(s: string; x: set[char]): int =
  for i in 0..<s.len:
    if s[i] in x: return i
  return -1

let whitespacePos = indexOf("abc def", {' ', '\t'})
echo whitespacePos
```
{==+==}

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

{==+==}

{==+==}
* Nim uses static typing, so the parameters have types attached: the input parameter named `s` has type `string`;
  `x` has the type "set of characters"; the function called `indexOf` produces an integer value as final result.
* You can iterate over the string index via the `for` loop, the goal is to find the position of the first character
  inside the string that matches the given set of values.
* When calling the function, we construct a set of characters covering the "whitespace" property using curly parentheses (`{}`).
{==+==}

* Nim使用静态类型，因此参数具有类型：名为 `s` 的输入参数具有类型 `string` ；
`x` 具有 "字符数组 set[char]" 类型；名为 `indexOf` 的函数生成一个整数值作为最终结果。
* 您可以通过 `for` 循环对字符串索引进行迭代，目标是找到字符串中第一个字符与给定值集匹配的位置。

* 在调用函数时，我们使用花括号 (`{}`) 构造一组覆盖“空白”属性的字符。


{==+==}

{==+==}
Having talked mostly about syntax so far, the take-away here is our first Zen rule:

> Concise code is not in conflict with readability, it enables readability.

As you can see in the above tiny example, it is very easy to follow and to read because we basically leave out the symbols
that carry little meaning, such as curly braces for blocks or semicolons to terminate the statements.
This scales up, so in longer programs it is really helpful when you have less code to look at, because then you can
more easily figure out how the code is supposed to work or what it can do (without getting too much details).
{==+==}

到目前为止，我们主要讨论了语法，这里的重点是我们的第一条禅法则：

> 简洁的代码与可读性并不冲突，它可以提高可读性。

正如你在上面的小例子中看到的，它很容易理解，因为我们基本上忽略了符号
它们没有什么意义，例如用于块的大括号或用于终止语句的分号。

这会扩大规模，因此在较长的程序中，当您需要查看的代码较少时，这会非常有用，因为这样您可以更容易地了解代码该如何工作或它可以做什么（而不需要获得太多细节）。

{==+==}

{==+==}
Usually the argument is like: "the syntax is terse, so it is unreadable and all you want to do is to save typing work";
in my opinion this totally misses the point, it is not about saving keystrokes or saving typing effort,
it is saving the effort when you **look** at the resulting code.
Programs are read way more often than they are written and when you read them it really helps if they are shorter.
{==+==}

通常情况下，参数是这样的："语法很简洁，因此不可读，您所要做的就是保存输入工作"；在我看来，这完全没有抓住重点，这不是为了节省击键或打字工作量，当您**查看**生成的代码时，这可以节省精力。程序的阅读频率比编写的频率高，当你阅读它们时，如果它们更短，那真的很有帮助。

{==+==}

{==+==}
## A smart compiler

The second rule for our Zen of Nim is:

> The compiler must be able to reason about the code.

This means we want:

- Structured programming.
- Static typing!
- Static binding!
- Side effects tracking.
- Exception tracking.
- Mutability restrictions (the enemy is shared mutable state, but if the state is not shared it is fine to mutate it: we want to be able to do it precisely).
- Value based datatypes (aliasing is very hard to reason about!).

We will see now what these points mean in detail.
{==+==}

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

{==+==}

{==+==}
### Structured programming

In the following example the task is to count all the words in the file (given by `filename` as a `string`),
and produce a count table of strings, so in the end there will be entries for every word and how often it occurs in the text.

```nim
import tables, strutils

proc countWords(filename: string): CountTable[string] =
  ## Counts all the words in the file.
  result = initCountTable[string]()
  for word in readFile(filename).split:
    result.inc word
  # 'result' instead of 'return', no unstructed control flow
```
{==+==}

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

{==+==}

{==+==}
Thankfully, the Nim standard library already offers us a `CountTable` so the first line of the `proc`
is the new count table.
`result` is built into Nim and it represents the return value so you
do not have to write `return result` which is unstructured programming,
because `return` immediately leaves every scope and returns back the result.
Nim does offer the `return` statement but we advise you to avoid it for this reason, since that is unstructured programming.
{==+==}

幸运的是，Nim 标准库已经提供了一个 `CountTable`，因此  `proc` 的第一行是新的计数表。
 `result`  内置于 Nim 中，它表示返回值，因此您不必编写非结构化编程的 `return result` ，因为  `return` 立即离开每个范围并返回结果。 Nim 确实提供了 `return` 语句，但我们建议您不要使用它，因为这是非结构化编程。

{==+==}

{==+==}
In the rest of the `proc`, we read the file into a single buffer, we split it to the get the single word and we count the word via
`result.inc`.

Structured programming means you have a single entry point into a block of code and a single exit point.

In the next example, I leave the `for` loop body in a more convoluted manner, with a `continue` statement:
{==+==}

在 `proc` 的其余部分中，我们将文件读入单个缓冲区，将其拆分为单个单词，然后通过 `result.inc` 计算单词数。

结构化编程意味着代码块只有一个入口点和一个出口点。

在下一个示例中，我以更复杂的方式使用 `continue` 语句离开 `for` 循环体：

{==+==}

{==+==}
```nim
for item in collection:
  if item.isBad: continue
  # what do we know here at this point?
  use item
```

* For every item in this collection if the item is bad we continue and otherwise we use the item.
* What do I know after the continue statement? well, I know that the item is not bad.

Why then not write it in this way, using structured programming:
{==+==}

```nim
for item in collection:
  if item.isBad: continue
  # what do we know here at this point?
  use item
```

* 对于此集合中的每个项目，如果项目不好将继续循环，否则将使用该项目。
* 在 `continue` 语句之后我知道什么？我知道这个项目不错。

为什么不这样写呢？使用结构化编程：

{==+==}

{==+==}
```nim
for item in collection:
  if not item.isBad:
    # what do we know here at this point?
    # that the item is not bad.
    use item
```

* The indentation here gives us clues about the invariances in our code, so that we can see much more easily
  that when I `use item` the invariant holds that the item is not bad.
{==+==}

```nim
for item in collection:
  if not item.isBad:
    # what do we know here at this point?
    # that the item is not bad.
    use item
```
* 这里的缩进使用了代码中的固定值，这样我们可以更容易地看明白，当我 “使用项目”时，固定值认为该项目不坏。

{==+==}

{==+==}
If you prefer the `continue` and `return` statements, that is fine, it is not a crime to use them,
I use them myself if nothing else works, but you should try to avoid it and more importantly it means that
we will probably never add a more general go-to statement to the Nim programming language
because go-to is even more against the structured programming paradigm.
We want to be in this position where we can prove more and more properties about your code
and structured programming makes it much easier for a proof engine to help with this.
{==+==}

如果您喜欢用 `continue` 和 `return` 语句，也可以，使用它们并不犯错。如果其他方法都不起作用，我自己也会使用它们，但您应该尽量避免使用。更重要的是，这意味着我们可能永远不会在 Nim 编程语言中添加更通用的 go to 语句，因为 go to 更不符合结构化编程范式。

我们希望处于这样的位置，可以展示代码越来越多的属性，结构化编程可以帮助实现这一点。

{==+==}

{==+==}
### Static typing

Another argument for static typing is that we really want you to use custom types dedicated to the problem domain.

Here we have a little example showing you the `distinct string` feature (with `enum` and `set`):

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
{==+==}

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


{==+==}

{==+==}
* `NimCode` can be stored as a `string` but it is a `distinct string` so it is a special type
  with special rules.
* The `proc runNimCode` can run arbitrary Nim code that you passed to it, but it is a virtual machine
  that can run the code and it can restrict what is possible.

{==+==}

*  `NimCode` 可以存储为 `string` ，但它是一个不同的字符串 `distinct string` ，因此它是一种具有特殊规则的特殊类型。

*  `proc runNimCode` 可以运行传递给它的任意 Nim 代码，但它是一个可以运行代码的虚拟机，它可以限制可能的操作。

{==+==}

{==+==}
* There is a sandbox environment in this example and there are custom properties that you might want to use.
  For instance you can say: allow the nim `cast` operation (`allowCast`) or allow the function foreign interface (`allowFFI`);
  the last option is about allowing Nim code to run into infinite loops (`allowInfiniteLoops`).
* We put the options in an ordinary `enum` and then we can produce a `set` of enums, indicating that
  every option is independent of the others.
{==+==}

* 本例中有一个沙盒环境，您可能想使用一些自定义属性。例如，您可以说：允许 Nim `cast` 操作  (`allowCast`)  或允许外部函数接口 (`allowFFI`) ；最后一个选项是允许 Nim 代码运行到无限循环中 (`allowInfiniteLoops`)。

* 我们将选项放在一个普通的 `enum` 中，然后我们就可以生成一组 `set` 枚举，表示每个选项是独立的。

{==+==}

{==+==}
If you compare the above to C for instance, where it is common to use the same mechanism, you lose the type safety:

```c
#define allowCast (1 << 0)
#define allowFFI (1 << 1)
#define allowInfiniteLoops (1 << 2)

void runNimCode(char* code, unsigned int flags = allowCast|allowFFI);

runNimCode("4+5", 700); // nobody stops us from passing 700
```
{==+==}

例如，如果将上述内容与 C 进行比较，在 C 中使用相同的机制是常见的，但会失去类型安全性：

```c
#define allowCast (1 << 0)
#define allowFFI (1 << 1)
#define allowInfiniteLoops (1 << 2)

void runNimCode(char* code, unsigned int flags = allowCast|allowFFI);

runNimCode("4+5", 700); // nobody stops us from passing 700
```


{==+==}

{==+==}
* When calling `runNimCode`, `flags` is only an unsigned integer and nobody stops you from passing the value 700
  even though it does not make any sense.
* You need to use bit twiddling operations to define `allowCast`, ... `allowInfiniteLoops`.

You lose information here: even though it is very much in the programmer's head what is really a valid
value for this `flags` argument, yet it is not written down in the program, so the compiler cannot really help you.
{==+==}

* 当调用 `runNimCode` 时，`flags` 只是一个无符号整数，没有人阻止您传递值700，即使它没有任何意义。

* 您需要使用位转换操作来定义 `allowCast`，... `allowInfiniteLoops`。

你在这里失去了信息：尽管程序员的头脑中非常清楚这个 `flags`  参数的真正有效值是什么，但它并没有写在程序中，所以编译器不能帮助你。

{==+==}

{==+==}
### Static binding

We want Nim to use static binding. Here is a modified "hello world" example:

```nim
echo "hello ", "world", 99
```

what happens is that the compiler rewrites the statment to:

```nim
echo([$"hello ", $"world", $99])
```
{==+==}

### 静态绑定

我们希望 Nim 使用静态绑定。下面是一个经过修改的 `hello world` 示例：

```nim
echo "hello ", "world", 99
```

这样编译器会将状态重写为：

```nim
echo([$"hello ", $"world", $99])
```

{==+==}

{==+==}
- `echo` is declared as: ``proc echo(a: varargs[string, `$`]);``
- `$` (Nim's `toString` operator) is applied to every argument.
- We use overloading (of the `$` operator in this case) instead of dynamic binding (as it would be done for example in C#).
{==+==}

- `echo` 声明为：``proc echo(a: varargs[string, `$`]);``
- `$` （Nim 的  `toString` 运算符）应用于每个参数。
- 我们使用重载（在本例中为 `$` 运算符）而不是动态绑定（例如在C#中）。

{==+==}

{==+==}
This mechanism is extensible:

```nim
proc `$`(x: MyObject): string = x.s
var obj = MyObject(s: "xyz")
echo obj  # works
```
{==+==}

该机制是可扩展的：

```nim
proc `$`(x: MyObject): string = x.s
var obj = MyObject(s: "xyz")
echo obj  # works
```


{==+==}

{==+==}
* Here I have my custom type `MyObject` and I define the `$` operator to actually return just the `s` field.
* Then, I construct a `MyObject` with value `"xyz"`.
* `echo` understands how to echo these objects of type `MyObject` because they have a dollar operator defined.
{==+==}

* 在这里，一个自定义类型 `MyObject` ，定义了 `$` 运算符，实际上只返回 `s` 字段。
* 然后，构造一个值为 `"xyz"` 的 `MyObject` 。
* `echo` 了解如何打印类型为 `MyObject` 的对象，因为它们定义了一个 `$` 运算符。

{==+==}

{==+==}
### Value based datatypes

We want value based data types so that the program becomes easier to reason about.
I have already said we want to restrict the shared mutable state.
One solution that is usually overlooked by functional programming languages is that in order to do that
you want to restrict aliasing and not the mutation.
Mutation is very direct, convenient and efficient.
{==+==}

### 基于值的数据类型

我们需要基于值的数据类型，以便程序更容易推理。

我说过要限制可变状态共享。

函数式编程语言通常忽略的一个解决方案是，为了做到这一点，您需要限制别名，而不是转换。

转换非常直接、方便和有效。

{==+==}

{==+==}
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

The fact that the assignment `other = r` performed a copy, means that there is no spooky action at a distance involved here,
there is only one access path to `r.x` and `other.x` is not an access path to the same memory location.
{==+==}

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

{==+==}

{==+==}
### Side effects tracking

We want to be able to track side effects.
Here is an example where the goal is to count the number of substrings inside a string.

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
{==+==}

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

{==+==}

{==+==}
Let us assume that this is not correct code and there is a debug `echo` statement.
The compiler would complain: you say proc has no side effect but echo produces a side effect,
so you are wrong, go fix your code!
{==+==}

让我们假设这是错误的代码，并且存在调试 `echo` 语句。
编译器会抱怨：你说过程没有副作用，但 `echo` 会产生副作用，所以去修复代码吧！

{==+==}

{==+==}
The other aspect of Nim is that while the compiler is very smart and can help you, sometimes you need to get
work done and you must be able to override these very good defaults.
{==+==}

另一个方面,虽然 Nim 编译器非常聪明，可以帮助您，但你仍需要做些工作，覆盖这些好的默认值。

{==+==}

{==+==}
So if I say: "okay, I know this does produce a side effect, but I don't care
because this is only code I added for debugging" you can say: "hey, cast this body of code
to a `noSideEffect` effect" and then the compiler is happy and says "ok, go ahead":
{==+==}

所以如果我说：“好吧，我知道这会产生副作用，但我不在乎，因为这是我为调试添加的唯一代码，你可以说：“嘿，将这段代码转换为  `noSideEffect` 效果”，然后编译器很高兴，并说“好，继续”：

{==+==}

{==+==}
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
{==+==}
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


{==+==}

{==+==}
`cast` means: "I know what I am doing, leave me alone".

### Exception tracking

We want exception tracking!

Here I have my main `proc` and I want to say it raises nothing,
I want to be able to ensure that I handled every exception that can happen:
{==+==}

`cast` 的意思是：“我知道我在做什么，别管我”。

### 异常跟踪

我们需要异常跟踪！

这里是我的 `main proc` ，我想说它不会引发任何问题，我希望能确保处理了可能发生的每个异常：


{==+==}

{==+==}
```nim
import os

proc main() {.raises: [].} =
  copyDir("from", "to")
  # Error: copyDir("from", "to") can raise an
  # unlisted exception: ref OSError
```

The compiler would complain and say
"look, this is wrong, `copyDir` can raise an unlisted exception, namely `OSError`".
So you say, "fine, in fact I did not handle it", so now I can claim
that `main` raises `OSError` and the compilers says: "you are right!":
{==+==}

```nim
import os

proc main() {.raises: [].} =
  copyDir("from", "to")
  # Error: copyDir("from", "to") can raise an
  # unlisted exception: ref OSError
```
编译器会抱怨说 “看，这是错误的，`copyDir` 可以引发未列出的异常，即`OSError`”。

所以你说，“好吧，事实上我没有处理”，所以现在我可以说 `main` 引发 `OSError`，编译器说：“你说得对！”：

{==+==}

{==+==}
```nim
import os

proc main() {.raises: [OSError].} =
  copyDir("from", "to")
  # compiles :-)
```

We want to be able to parametrize over this a little bit:

```nim
proc x[E]() {.raises: [E].} =
  raise newException(E, "text here")

try:
  x[ValueError]()
except ValueError:
  echo "good"
```
{==+==}
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


{==+==}

{==+==}
- I have a generic `proc x[E]` (`E` is the generic type), and I say: "whatever `E` you pass to this `x`,
  that is what I am going to raise.
- Then I instantiate this `x` with this `ValueError` exception and the compiler is happy!

I was really surprised that this works out of the box.
When I came up with this example I was quite sure the compiler would produce a bug, but it is already
handling this situation very well and I think the reason for that is that somebody else helped out and fixed this bug.
{==+==}

- 我有一个泛型 `proc x[E]`（`E`是泛型类型），我说：“无论你传递给这个`x`的`E`，这就是我要提出的。

- 然后我用这个 `ValueError` 异常实例化这个 `x` ，编译器很高兴！

我真的很惊讶，这是开箱即用的。

当我提出这个例子时，我很确定编译器会产生一个bug，但它已经很好地处理了这种情况，我认为原因是其他人帮助解决了这个bug。

{==+==}

{==+==}
### Mutability restrictions

Here I am going to show and explain what the experimental `strictFuncs` switch does:

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
{==+==}
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


{==+==}

{==+==}
- I have a `Node` type which is a `ref object` and `next` and `prev` are pointers to these kind of objects
  (it is a doubly linked list). There is also a `data` field of type `string`.
- I have a function `len` and it counts the number of nodes that are in my linked list.
- The implementation is pretty straightforward: unless it is `nil` you count the node and then follow to `next` node.
{==+==}

- 有一个 `Node` 类型，它是一个 `ref object` ，`next` 和 `prev` 是指向这类对象的指针（这是一个双重链接列表）。还有一个类型为 `string` 的  `data` 字段。
- 有一个函数 `len` ，它计算链接列表中的节点数。

- 实现非常简单：除非它是 `nil` ，否则计算节点数，然后转到 `next` 节点。

{==+==}

{==+==}
The crucial point is that via `strictFuncs` we tell the compiler that parameters are now **deeply** immutable,
so the compiler is fine with this code and it is also fine with this example:

```nim
{.experimental: "strictFuncs".}

func insert(x: var seq[Node]; y: Node) =
  let L = x.len
  x.setLen L + 1
  x[L] = y
```
{==+==}



{==+==}

{==+==}
- I want to `insert` something but it is a `func` so it is **very** strict about my mutations.
- I want to append to `x`, which is a sequence of nodes, so `x` is **explicitly** mutable
via the `var` keyword (and `y` is not mutable).
- I can set `x`'s length as the old length plus one and then overwrite what is in there, and this is fine.

Finally, I can still mutate local state:
{==+==}



{==+==}

{==+==}
```nim
func doesCompile(n: Node) =
  var m = Node()
  m.data = "abc"
```

I have a variable `m` of type `Node`, but it is freshly created and then I mutate it and set the `data` field and
since it is not connected to `n` the compiler is happy.

The semantics are: "you cannot mutate what is reachable via parameters, unless these parameters are explicitly marked as `var`".

Here is an example where the compiler says:
"yeah, look, no, you are trying to mutate `n`, but you are in `strictFunc` mode so you are not allowed to do that"
{==+==}



{==+==}

{==+==}
```nim
{.experimental: "strictFuncs".}

func doesNotCompile(n: Node) =
  n.data = "abc"
```

We can now play these games and see how smart the compiler is.

Here I try to trick the compiler into accepting the code but I was not able to:
{==+==}



{==+==}

{==+==}
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
{==+==}



{==+==}

{==+==}
- `select` is a helper function that takes two nodes and simply returns the second one.
- Then I want to mutate `n` but I assign it to `it`, and then `it` to `x`, `x` to `y`, and `y` to `z`.
- Then I select either `x` or `z` and then mutate the `data` field and overwrite the string to value `"tricky"`.
{==+==}



{==+==}

{==+==}
The compiler will tell you "Error, an object reachable from `n` is potentially mutated"
and it will point out the statement that connects the graph to this parameter.
What it does internally is: it has a notion of an abstract graph and it starts with
"every graph that is constructed is disjoint", but depending on the body of your function,
these disjoint graphs can be connected.
When you mutate something, the graph is mutated and if it is connected to an input parameter,
then the compiler will complain.
{==+==}



{==+==}

{==+==}
So the second rule is:

> If the compiler cannot reason about the code, neither can the programmer.

We really want a smart compiler helping you out, because programming is quite hard.

## Meta programming features

Another rule that is kind of famous by now is:
{==+==}



{==+==}

{==+==}
> Copying bad design is not good design.

If you say "hey, language X has feature F, let's have that too!", you copy
this design but you do not know if it is good or bad, because you did not
start from first principles.
{==+==}



{==+==}

{==+==}
So, "C++ has compile-time function evaluation, let's have that too!".
This is not a reason for adding compile-time function evaluation,
the reason why we have it (and we do it very differently from C++),
is the following: "We have many use cases for feature F".
{==+==}



{==+==}

{==+==}
In this case F is the macro system:
"We need to be able to do locking, logging, lazy evaluation,
a typesafe Writeln/Printf, a declarative UI description language,
async and parallel programming! So instead of building these
features into the language, let's have a macro system."
{==+==}



{==+==}

{==+==}
Let's have a look at these meta programming features.
Nim offers **templates** and **macros** for this purpose.

### Templates for lazy evaluation

A template is a simple substitution mechanism.
Here I define a template named `log`:

```nim
template log(msg: string) =
  if debug:
    echo msg

log("x: " & $x & ", y: " & $y)
```
{==+==}



{==+==}

{==+==}
You can read it as some kind of function, but the crucial difference is that it expands the code directly in line
(where you invoke `log`).

You can compare the above to the following C code where `log` is a `#define`:

```c
#define log(msg) \
  if (debug) { \
    print(msg); \
  }

log("x: " + x.toString() + ", y: " + y.toString());
```
{==+==}



{==+==}

{==+==}
It is quite similar! The reason why this is a template (or a `#define`) is that we want
this message parameter to be evaluated lazily, because in this example I do perform
expensive operations like string concatenations and turning variables into strings
and if `debug` is disabled this code should not be run.
The usual argument passing semantics are: "evaluate this expression and then call the function",
but then inside the function you would notice that debug is disabled and that you do not need all this
information, so it does not have to be computed at all.
This is what this template achieves here for us, because it is expanded directly when invoked:
if `debug` is false then this complex expression of concats is not performed at all.
{==+==}



{==+==}

{==+==}
### Templates for control flow abstraction:

We can use templates for control flow abstractions.
If we want a `withLock` statement,
C# offers it is a language primitive, in Nim you do not have to build this into the language at all,
you just write a `withLock` template that acquires the `lock`:

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
{==+==}



{==+==}

{==+==}
- `withLock` acquires the lock and finally releases the lock.
- In between the locking section the full body is run, which can be passed to `withLock` statement via colon indentation syntax.

### Macros to implement DSLs

You can use macros to implement DSLs (Domain Specific Languages).

Here is a DSL for describing html code:

```nim
html mainPage:
  head:
    title "Zen of Nim"
  body:
    ul:
      li "A bunch of rules that make no sense."

echo mainPage()
```
{==+==}



{==+==}

{==+==}
It produces:

```html
<html>
  <head><title>Zen of Nim</title></head>
  <body>
    <ul>
      <li>A bunch of rules that make no sense.</li>
    </ul>
  </body>
</html>
```
{==+==}



{==+==}

{==+==}
### Lifting

You can use meta programming for "lifting" operations that come up again and again in programming.

For example, we have square root in `math` for floating point numbers and now
I want to have a square root operation that works for a list of floating point numbers.
I could use a `map` call, but I can also create a dedicated `sqrt` function:
{==+==}



{==+==}

{==+==}
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
{==+==}



{==+==}

{==+==}
- We pass `fname` to the template and `fname` is applied to every element of the sequence.
- The final name of the `proc` is also `fname` (in this case `sqrt`).
{==+==}



{==+==}

{==+==}
### Declarative programming

You can use templates to turn imperative code into declarative code.

Here I have an example extracted from our test suite:

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
{==+==}



{==+==}

{==+==}
There are threading tests called `tactors`, `tactors2` and `threadex` and every single of these tests
runs in three different configurations: with the default options, default options plus release switch,
default options plus thread local storage emulation.
This `threadTests` call takes many parameters (like category and options and filename),
which is just distracting when you copy and paste it over and over again,
so here we want to say "I have a test that is called `tactors`, I have a test that is called `tactors2`
and I have a test that is called `threadex`" and by shortening this you are now working at the level of abstraction
that you actually want to work on:
{==+==}



{==+==}

{==+==}
```nim
test "tactors"
test "tactors2"
test "threadex"
```

You can shorten this further, since all these test invocations are kind of annoying.
What I really want to say is:
{==+==}



{==+==}

{==+==}
```nim
test "tactors", "tactors2", "threadex"
```

Here is a simple macro that does that:

```nim
import macros

macro apply(caller: untyped;
            args: varargs[untyped]): untyped =
  result = newStmtList()
  for a in args:
    result.add(newCall(caller, a))

apply test, "tactors", "tactors2", "threadex"
```
{==+==}



{==+==}

{==+==}
Since it is so simple, it is not able to accomplish the full thing and you need to say `apply test`.
This macro produces a list of statements, and every statement inside this list is actually a call expression
calling this `test` with `a` (`a` is the current argument and we iterate over every argument).
{==+==}



{==+==}

{==+==}
The details are not really that important, the crucial insight here is that Nim gives you
the capabilities of doing these things and once you get used to it, it is remarkably easy.

### Typesafe Writeln/Printf

The next example is a macro system that gives us a type safe `printf`:
{==+==}



{==+==}

{==+==}
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
{==+==}



{==+==}

{==+==}
- Same thing as before, we create a statement list in the first line of the macro and then we iterate over every argument
  and we produce a function call called `write`.
- The `bindSym"write"` binds `write` but this is not a single `write`, it is
  an overloaded operation because I have three `write` operations at the start of the example (for `int`, `bool` and `float`),
  and overloading resolution kicks in and picks the right `write` operation.
- Finally, the last line of the macro, there is a call to a `writeNewline` function that was declared earlier (which produces a new line).
{==+==}



{==+==}

{==+==}
## A practical language

The compiler is smart but:

> Don't get in the programmer's way

We have a tremendous amount of code written in C++, C and Javascript that programmers really need to reuse.
We accomplishing this **interoperability with C++, C and JavaScript**, by compiling Nim to these languages.
Note that this is for interoperability, the philosophy is not:
"let's use C++ plus Nim, because Nim does not offer some features that are required to get the job done".
Nim does indeed offer low level features such as:
{==+==}



{==+==}

{==+==}
* bit twiddling,
* unsafe type conversions ("cast"),
* raw pointers.

Interfacing with C++ is the last resort, usually we want you to write Nim code
and not leave Nim code, but then the real world kicks in and says:
"hey, there's a bunch of code already written in these languages,
how about you make the interoperability with these systems very good".
{==+==}



{==+==}

{==+==}
We do not want Nim to be just one language out of many and then you use different programming languages
to accomplish your system. Ideally, you only use the Nim language because that is much cheaper to do.
Then you can hire programmers that only know a single programming language rather than four (or whatever you need).

The interoperability story goes so far that we actually offer an `emit` statement where you can directly put
foreign code into your Nim code and the compiler merges these two things together in the final file.
{==+==}



{==+==}

{==+==}
Here is an example:

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
{==+==}



{==+==}

{==+==}
You can emit a `static int cvariable` and the communication is two way,
so you can emit a `fprintf` statement where the variable `nimVar` is actually coming from Nim
(using the bracket notation you can have both strings and name expressions in the same environment).
The C code can use Nim code and viceversa.
However, this is really not a good way to do this interfacing,
it is just to show that we want you to be able to get things done.
{==+==}



{==+==}

{==+==}
A much better way for interoperability is where you can actually tell Nim: "hey, there is an `fprintf` function, 
it is coming from C and these are its types, I want to be able to call it".
Still, the `emit` pragma gets the point across very well that **we want this language to be practical**.
{==+==}



{==+==}

{==+==}
## Customizable memory management

Now a different topic, so far we did not talk about memory management.
In the newer Nim versions it is based on destructors
and it is called the `gc:arc` or `gc:orc` mode.
Destructors and ownership are hopefully familiar notions from C++ and Rust.
{==+==}



{==+==}

{==+==}
The `sink` parameter here means that the function gets ownership of the string
(and then it does not do anything with `x`):

```nim
func f(x: sink string) =
  discard "do nothing"

f "abc"
```
{==+==}



{==+==}

{==+==}
The question is: "did I produce a memory leak? what happens?".
You can ask the Nim compiler:
"hey, expand this function `f` for me; show me where the destructors are, where moves are performed,
where deep copies are performed"
(compile with `nim c --gc:orc --expandArc:f $file`).
{==+==}



{==+==}

{==+==}
The compiler would tell you "look, function `f` is actually your discard statement and I added this call
to the destructor at the end":

```nim
func f(x: sink string) =
  discard "do nothing"
  `=destroy`(x)
```

The nice thing is that **Nim's intermediate language is Nim itself**,
so Nim is this one language that can express everything very well.
{==+==}



{==+==}

{==+==}
Here I have a different example:

```nim
var g: string

proc f(x: sink string) =
  g = x

f "abc"
```
{==+==}



{==+==}

{==+==}
This time I take ownership of `x` and I really do something with the ownership,
namely I put `x` into this global variable `g`.
Again, we can ask the compiler what does it do and the compiler says:
"this is a move operation, it is called `=sink`".
So we move the `x` into the `g` and the move takes care of freeing what is inside the `g`
(if there is something) and then it takes `x`'s value over:
{==+==}



{==+==}

{==+==}
```nim
var g: string

proc f(x: sink string) =
  `=sink`(g, x)

f "abc"
```

What it really did, and unfortunately that is not really visible here, is that
it says: "okay, `x` is moved into `g` and then we say `x` was moved
and call the destructor", but these `wasMoved` and `=destroy` calls cancel out so
that the compiler optimized this for us:
{==+==}



{==+==}

{==+==}
```nim
var g: string

proc f(x: sink string) =
  `=sink`(g, x)
  # optimized out:
  wasMoved(x)
  `=destroy`(x)

f "abc"
```

### A custom container

You can use these moves, destructors and copy assignments to create custom data structures.

Here I have a short example, but I will not go into much details.
{==+==}



{==+==}

{==+==}
**Destructor**:

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
{==+==}



{==+==}

{==+==}
**Move operator**:

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
{==+==}



{==+==}

{==+==}
**Assignment operator**:

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
{==+==}



{==+==}

{==+==}
**Accessors**

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

The point here is that destructors, move operators, ... can be written by you for your
custom containers and then they work well with Nim's built-in containers,
but it also gives you very precise control over the memory allocations and how they are done.

So another Zen rule is:

> Customizable memory management
{==+==}



{==+==}

{==+==}
## Zen of Nim

Here are the rules once again as a summary:

- **Copying bad design is not good design**: we want to create good design by reasoning from first principles
  about the problem.
- **If the compiler cannot reason about the code, neither can the programmer**.
- However, **don't get in the programmer's way**. The compiler is a smart dog: you can teach it new tricks
  and it really helps you out, it can perform tasks for you like carrying a newspaper, but in the end
  the programmer is still smarter than the compiler.
- We want to **move work to compile-time** because **programs are run more often than they are compiled**.
{==+==}



{==+==}

{==+==}
- We want **customizable memory management**.
- **Concise code is not in conflict with readability, it enables readability**.
- There was this rule of Zen that was like **leverage meta programming to keep the language small**,
  however it is hard to say that and keep a straight face when Nim really offers quite a lot of features.
  There is a friction between "we want the language to be complete" and "we want the language to be minimal".
  The older Nim gets the more Nim is about completeness (all minimal languages grow to serve certain needs).
- **Optimization is specialization**. I have not talked about this yet, but **when you need more speed**,
  you should really consider to **write custom code**. The Nim standard library cannot offer everything to everybody
  and for us it is also much harder to give you the best library for everything, because the best library must be general purpose, 
  it must be the fastest library, it must have the least amount of overhead for your compile times, and that is very hard to accomplish.
  It is much easier to say "ok, Nim offers this as a standard library, but here I wrote this myself in 10 lines and I can
  benchmark it and usually my custom code is faster, because it is hand tailored to the application that I am writing".
  So the really is: specialize your code and then it will run fast.
{==+==}



{==+==}

{==+==}
- Finally, **there should be one and only one programming language for everything. That language is Nim.**

Thank you for reading!
{==+==}



{==+==}
