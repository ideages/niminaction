Nim 2.0 的改进
============

原文作者：
<https://ssalewski.de/nimprogramming.html#_changes_for_nim_2_0_2>

在2019年发布了尼姆1.0版，2022年11月发布了尼姆1.6.10版之后，伦普夫（Araq Rumpf）先生将于2023年初发布尼姆2.0版。虽然Nim 2.0带来了一些重要的变化和改进，但Nim 1.6和Nim 2.0之间应该没有严重的不兼容问题，为Nim 2.0改编旧程序应该不难，只要旧程序不使用难看的黑科技。不幸的是，Nim 2.0与其他实现（如https://github.com/nim-works/nimskull 的不兼容可能会出现。未来将显示，替代实现是否会尝试与Rumpf的实现尽可能兼容，或者它们是否会创建新语言方言，甚至是使用新名称的新语言，如 Cyo 或 nimskulle 。我们已经对尼姆标准库的模块进行了类似的处理，这些模块已经被 Status 公司创建的不兼容、改进的变体（例如。https://github.com/status-im/nim-taskpools 和 https://github.com/status-im/nim-chronos)以及其他尼姆贡献者。

Nim 2.0最重要的改进是ORC内存管理系统现在是默认的。我们已经在书中提到了Nim 2.0的一些新功能，我们将在接下来的几节中总结Nim 2.0最重要的变化：


ARC/ORC内存管理
--------------

最初，Nim使用传统的垃圾收集器进行自动内存管理，这与大多数其他高级编程语言的做法类似。对于时间关键或资源有限的系统，传统垃圾收集器有一些严重的缺点，例如完全阻塞系统几毫秒，或者延迟释放资源，需要大量内存。早期的Java实现受到了这种影响，因此一些现代高性能语言，如Rust、Zig或Jai，根本不使用自动内存管理。像Nim和VLang这样的语言试图找到避免传统垃圾收集器缺点的自动内存策略。尼姆已经成功了，而弗拉格似乎还有很多路要走。ARC是一个确定性的、基于析构函数的内存管理系统：一旦被引用，堆分配的对象就超出了范围，因此任何引用都无法再访问它们，堆对象就会立即被释放。只要被引用的对象不构建循环结构，例如在曲面的三角剖分等图中，所有顶点和边都可能具有相邻引用，这就非常有效。为了处理周期，创建了ORC内存处理程序，现在是默认的。对于许多应用，如果使用传统的refc GC系统或ARC/ORC，这并不重要。REFC可能仍然有很小的性能优势，但ARC/ORC对于关键应用非常有效。有了ARC/ORC，Nim程序的行为应该像只有手动内存管理的程序，而没有纯内存管理的所有缺点，如双释放、悬空指针或内存泄漏。当你的程序不使用循环数据结构时，你现在可以使用arc。当你知道你使用循环时，比如对于Delaunay三角剖分，你应该使用orc来确保所有未引用的对象都能立即释放。使用选项-mm:orc编译的程序通常比使用--mm:arc编译的程序大10 kB。这两个选项生成的可执行文件都比--mm:refc小得多。对于性能关键型程序，进行一些测试总是一个好主意，因为refc或甚至其他GC选项（如boehm）可能会提供更大的吞吐量。目前，Nim无法报告ARC是否足够，或者由于循环引用而需要ORC。因此，如果您不确定，可能需要进行一些测试，例如将进程末尾的所有引用设置为nil，然后调用GC_fullCollect（）和GC_getStatics（）来监视仍然占用的内存资源。


**对象字段的默认值**

Nim默认将变量初始化为二进制零，这也适用于对象字段。在v2.0之前，无法在类型定义中为对象字段指定其他默认值。Nim 2.0现在终于可以像我们对普通变量一样实现这一点了。我们已经在Prim算法一节中使用了这个特性，在那里我们将Vertex的dist字段设置为math.Inf，这表明我们还没有找到邻居。


```nim
type
  Vertex = ref object
    x, y: float
    friend: Vertex
    dist: float = Inf
```

当默认零没有意义或甚至可能导致运行时异常（如分数的分母或缩放参数）时，对象字段的默认值非常有用，通常默认值为1或100%，但值为零。

**可重载枚举**

在Nim 2.0之前，在较大的程序中使用枚举可能非常冗长，因为不同的枚举类型可能具有相同名称的成员，因此我们必须使用 `pure` pragma，并将枚举值前缀为类型名称。为了避免这种情况，一些模块使用带有前缀的值，如 `nkProc` 。在枚举类型一节中，我们有两个具有几个公共值的枚举：

```nim
type
  TrafficLigth {.pure.} = enum
    red = "Stop"
    yellow = (2, "Caution")
    green = ("Go")

type
  BaseColor {.pure.} = enum
    red, green, blue

var caution: set[TrafficLigth] = {TrafficLigth.yellow, red}

echo caution # {Stop, Caution}
```

对于Nim 2.0，编译器现在很聪明，并且知道在 `{TrafficLigth.yellow, red}` 中，红色值也来自 `TrafficLight` 数据类型，因此我们不必使用类型名称前缀。不再需要 `{.pure.}` 编译指示 ，编译器非常聪明：只有 `"var caution = {red, blue}"` 这样的语句，如果没有其中一个值的类型前缀，显然无法编译。

**C字符串限制**

Nim的字符串是可变值对象，具有长度和容量财产，并具有复制语义。由于实际的Nim字符串数据缓冲区是堆分配的，以NULL结尾，因此它与C语言中的字符串数据类型兼容，后者基本上是指向字符（*char）的指针。在早期的Nimrod中，我们经常使用Nim-cstring数据类型作为C语言中字符串的别名。在现代Nim中，cstring代表兼容字符串，这是一个与C和JavaScript后端兼容的字符串。在Nim 2.0中，cstrings已成为二等公民。我们可以毫无问题地使用cstring作为C库函数的参数，但是当我们将cstring数据类型的变量传递给一个普通的Nim进程时，我们会得到一个严重的警告：


```nim
proc callCLib(s: cstring) =
  discard # call a C library

proc indirectCallCLib(s: cstring) =
  callCLib(s)

var a = "Test"
indirectCallCLib(a)
```

```bash
Warning: implicit conversion to 'cstring' from a non-const location: a; this will become a compile time error in the future [CStringConv]
```
警告：从非常量位置隐式转换为“cstring”：a；这将在将来成为编译时错误[CStringConv]

这可能是合理的，例如，因为 `cstring` 无法增长，并且修改 `cstring` 可能会使初始 Nim 字符串无效。但同时，当我们通过跳转动作间接调用 C 库时，这种行为也是一个问题。我们得到了上述警告，程序将来可能不再编译。一个可能的解决方案是，我们将普通的 Nim 字符串传递给跳转进程。但这可能是一些开销，因为我们传递了一个对象而不是一个普通指针，最重要的是，我们不能再向 C 库传递 `nil/NULL` 。但是对于某些 C 库，`nil/NULL`与空字符串非常不同。


**StrictDefs**

In Nim, variables are generally initialized with binary zero, that is, zero for numerical values, nil for references and pointers, and "" for strings. With Nim 2.0, we can use the strictDefs pragma, which seems to be currently only available in the form {.experimental: "strictDefs".}, to enforce the explicit initialization of variables:

**StrictDefs**

在Nim中，变量通常用二进制零初始化，即数值为零，引用和指针为零，字符串为“”。在Nim 2.0中，我们可以使用 `strictDefs` 编译指示来强制变量的显式初始化，该pragma目前似乎只能以 `{.experimental: "strictDefs".}` 的形式提供：


```nim
{.experimental: "strictDefs".}

proc main =
  var a: int
  echo a
  let b: int
  if a == 0:
    b = 1
  else:
    b = 2
  echo b

main()
```

编译上述代码现在会发出警告：
`Warning: use explicit initialization of 'a' for clarity [Uninit]`

警告：为清晰起见，请使用“a”的显式初始化[Uninit]

这可能是后来的默认设置。同样，编译器是聪明的，并进行详细的代码分析：当我们在每个可能的代码路径中为变量赋值时，就不会出现警告。现在，这甚至适用于上面示例中的 `let` 语句。


**输出参数**

在2.0之前的Nim版本中，我们可以将未初始化的 `var` 参数传递给 procs ，然后由 procs 初始化该变量。虽然纯 Nim 函数通常避免了这种情况，并且我们使用函数返回值将值传递回调用者，但这种程序形状有时在C库中使用。[65]为了强制初始化未初始化传递给过程的参数，Nim 2.0引入了一些参数：


```nim
proc p(i: out int) =
  discard # i = 0

proc main =
  var n = 1
  p(n)
  echo n

main()
```

编译上述代码会导致此警告：

`Warning: Cannot prove that 'i' is initialized. This will become a compile time error in the future. [ProveInit]`

警告：无法证明“i”已初始化。这将在将来成为编译时错误。[证明初始化]

原因很明显，`proc p` 没有为 `out` 参数 `i` 赋值。


**StrictFuncs**

当我们将参数传递给函数和应该在函数主体中修改的函数时，我们必须使用 `var` 关键字使参数可变。对于初学者来说，有时令人惊讶的是，当我们将引用参数传递给函数时，它可以修改 `ref` 对象的字段，而当 `ref` 对象没有作为 `var` 参数传递时也是如此。因此，`var` 关键字只需要更改 `ref` 本身，例如，交换或初始化对象的 `ref` 。有了Nim 2.0中 `StrictFuncs` pragma的新定义，我们可以确保函数中ref对象的字段不能在函数中变异。

```nim
{.experimental: "strictFuncs".}

type
  R = ref object
    i: int

func p(arg: R): bool =
  arg.i = 0

var r = R()
discard p(r)
```

编译上面例子将显示下面错误信息：

`Error: cannot mutate location arg.i within a strict func`

**Unicode运算符**

在Nim 2.0中，我们可以使用几个Unicode运算符；看见https://nim-lang.github.io/Nim/manual.html#lexical-有关详细信息，请查找unicode运算符。当我们创建数学库时，这可能会产生更干净的代码，例如，我们可以使用Unicode符号作为向量的叉积。输入这些Unicode符号可能很困难。在输入Unicode字符一节中，我们学习了如何键入Unicode符号。您可能还发现Linux（Gnome）工具gucharmap很有用：启动该工具，从菜单中选择View/By Unicode Block，然后选择Mathematic Operators。

```nim
proc `∘`(a, b: int): int =
  a * b + 1

echo `∘`(1, 2) # 3
echo 2 ∘ 3 # 7
```

**块中未命名的`break`**

在Nim 2.0中，在块中使用纯中断语句会发出警告。此警告在以后的Nim版本中可能会成为错误。我们可以使用带有命名 `break` 语句的命名块 来解决此问题：

```nim
block:
  echo 1
  break # warning, later an error
  echo 2

block t:
  echo 3
  break t # OK
  echo 4
```

结束
---

-----


当然，2.2版本也在`RFC`路线图中:
https://github.com/nim-lang/RFCs/issues/503
