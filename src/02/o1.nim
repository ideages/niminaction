# type
#   Node = ref object
#     data: int

# var x = Node(data: 3)
# let dangling = x
# assert dangling.data == 3
# # dispose(x)
# x = Node(data: 4)
# assert dangling.data in {3, 4}


# type
#   Node = object
#     data: int

# var nodes: array[4, Node]

# var x = 1
# nodes[x] = Node(data: 3)
# let dangling = x
# assert nodes[dangling].data == 3
# nodes[x] = Node(data: 4)
# assert nodes[dangling].data == 4


# type
#   Node = ref object
#     data: int

# var x = Node(data: 3) # inferred to be an ``owned ref``
# let dangling: Node = x # unowned ref
# assert dangling.data == 3
# x = Node(data: 4) # destroys x! But x has dangling refs --> abort.


# s双向链表
type
  Node*[T] = ref object
    prev*: Node[T]
    next*: owned Node[T]
    value*: T
  
  List*[T] = object
    tail*: Node[T]
    head*: owned Node[T]

proc append[T](list: var List[T]; elem: owned Node[T]) =
  elem.next = nil
  elem.prev = list.tail
  if list.tail != nil:
    assert(list.tail.next == nil)
    list.tail.next = elem
  list.tail = elem
  if list.head == nil: list.head = elem

proc delete[T](list: var List[T]; elem: Node[T]) =
  if elem == list.tail: list.tail = elem.prev
  if elem == list.head: list.head = elem.next
  if elem.next != nil: elem.next.prev = elem.prev
  if elem.prev != nil: elem.prev.next = elem.next