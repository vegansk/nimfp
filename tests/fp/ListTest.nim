import ../../src/fp/List, unittest, future

suite "List ADT":

  test "Initialization and conversion":
    let lst = [1, 2, 3, 4, 5].initList
    check(lst.head == 1)
    check(lst.tail.asSeq() == @[2, 3, 4, 5])
    check($lst == "List(1, 2, 3, 4, 5)")

