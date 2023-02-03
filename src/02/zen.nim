func `++`(x: var int; y: int = 1; z: int = 0) =
  x = x + y + z

var g = 70

++g

g ++ 7

# 反引号中的运算符被视为一个函数 'f':
g.`++`(10, 20)

echo g  # writes 108


###

func indexOf(s: string; x: set[char]): int =
  for i in 0..<s.len:
    if s[i] in x: return i
  return -1

let whitespacePos = indexOf("abc def", {' ', '\t'})
echo whitespacePos
