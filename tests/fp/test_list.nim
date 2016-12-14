import ../../src/fp/list, ../../src/fp/option, unittest, future

suite "List ADT":

  test "Initialization and conversion":
    let lst = [1, 2, 3, 4, 5].asList

    check: lst.head == 1
    check: lst.headOption == some(1)
    check: lst.tail.asSeq == @[2, 3, 4, 5]
    check: Nil[int]().headOption == 1.none
    check: $lst == "List(1, 2, 3, 4, 5)"
    check: 1^^2^^3^^4^^5^^Nil[int]() == lst
    check: ["a", "b"].asList != ["a", "b", "c"].asList

    check: 1.point(List) == [1].asList

  test "Fold operations":
    let lst = lc[x|(x <- 1..4),int].asList

    check: lst.foldLeft(0, (x, y) => x + y) == 10
    check: lst.foldLeft(1, (x, y) => x * y) == 24

    check: lst.foldRight(0, (x, y) => x + y) == 10
    check: lst.foldRight(1, (x, y) => x * y) == 24

    check: lst.foldRightF(() => 0, (x: int, y: () -> int) => x + y()) == 10
    check: lst.foldRightF(() => 1, (x: int, y: () -> int) => x * y()) == 24

    proc badAcc(): int = raise newException(Exception, "Not lazy!")
    check: lst.foldRightF(badAcc, (x: int, y: () -> int) => x) == 1

    check: Nil[int]().foldRight(100, (x, y) => x + y) == 100

  test "Transformations":
    check: @[1, 2, 3].asList.traverse((x: int) => x.some) == @[1, 2, 3].asList.some
    check: @[1, 2, 3].asList.traverse((x: int) => (if x > 2: x.none else: x.some)) == List[int].none

    # traverse should not call f after the first None
    var cnt = 0
    let res = asList(1, 2, 3).traverse do (x: int) -> auto:
      inc cnt
      if x != 2: x.some
      else: int.none
    check: res == List[int].none
    check: cnt == 2

    check: @[1.some, 2.some, 3.some].asList.sequence == @[1, 2, 3].asList.some
    check: @[1.some, 2.none, 3.some].asList.sequence == List[int].none

  test "Drop operations":
    let lst = lc[x|(x <- 1..100),int].asList

    check: lst.drop(99) == [100].asList
    check: lst.dropWhile((x: int) => x < 100) == [100].asList

  test "Misc functions":
    let lst = lc[$x | (x <- 'a'..'z'), string].asList
    check: lst.dup == lst
    check: lst.reverse == lc[$(('z'.int - x).char) | (x <- 0..('z'.int - 'a'.int)), string].asList
    check: asList(2, 4, 6, 8).forAll((x: int) => x mod 2 == 0) == true
    check: asList(2, 4, 6, 9).forAll((x: int) => x mod 2 == 0) == false
    check: asList(1, 2, 3).zip(asList('a', 'b', 'c')) == asList((1, 'a'), (2, 'b'), (3, 'c'))
    check: asList((1, 'a'), (2, 'b'), (3, 'c')).unzip == (asList(1, 2, 3), asList('a', 'b', 'c'))
    check: [1,2,3].asList.zipWithIndex(-1) == [(1, -1), (2, 0), (3, 1)].asList

    check: asList(1, 2, 3).contains(2)
    check: not asList(1, 2, 3).contains(4)

    check: asList((1, 'a'), (2, 'b'), (2, 'c')).lookup(1) == 'a'.some
    check: asList((1, 'a'), (2, 'b'), (2, 'c')).lookup(2) == 'b'.some
    check: asList((1, 'a'), (2, 'b'), (2, 'c')).lookup(3) == char.none

    check: asList(1, 2, 3).span((i: int) => i <= 2) == (asList(1, 2), asList(3))
    check: asList(1, 2, 3).span((i: int) => i mod 2 == 1) == (asList(1), asList(2, 3))
    check: asList(1, 2, 3).span((i: int) => true) == (asList(1, 2, 3), Nil[int]())

    check: asList(1, 2, 3).partition((i: int) => i > 2) == (asList(3), asList(1, 2))
    check: asList(1, 2, 3).partition((i: int) => i == 2) == (asList(2), asList(1, 3))
    check: asList(1, 2, 3).partition((i: int) => i > 4) == (Nil[int](), asList(1, 2, 3))
    check: asList(1, 2, 3).partition((i: int) => i > 0) == (asList(1, 2, 3), Nil[int]())

  test "Iterators":
    let lst1 = [1, 2, 3, 4, 5].asList
    var lst2 = Nil[int]()
    for x in lst1:
      lst2 = Cons(x, lst2)
    check: lst2 == lst1.reverse

    let lst3 = [1, 2, 3, 4, 5].asList
    for i, x in lst3:
      check: i == x.pred

  test "List - traverse with Option should allow to properly infer gcsafe":
    proc f(i: int): auto = i.some

    proc g(): auto {.gcsafe.} =
      asList(1, 2, 3).traverse(f)

    discard g()

  test "Traversable":
    check: asList(asList(1)) == asList(1)
    check: asList(1.some) == asList(1)
    check: asList([1.some].asList) == [1.some].asList
    when compiles(asList(1.some) == [1.some].asList):
      check: false

  test "Kleisli":
    let f = (v: int) => asList(v, v + 1, v + 2)
    let g = (v: int) => asList(v, v * 2, v * 3)
    check: 1.point(List) >>= (f >=> g) == asList(1, 2, 3, 2, 4, 6, 3, 6, 9)
