type Thing = object # <1>
  a: uint32
  b: uint8
  c: uint16

var t: Thing  #<2>

echo "size t.a ", t.a.sizeof
echo "size t.b ", t.b.sizeof
echo "size t.c ", t.c.sizeof
echo "size t   ", t.sizeof  #<3>

echo "addr t.a ", t.a.addr.repr
echo "addr t.b ", t.b.addr.repr
echo "addr t.c ", t.c.addr.repr
echo "addr t   ", t.addr.repr  #<4>

