import ../../src/fp/list, ../../src/fp/option, unittest, future

{.warning[TypelessParam]: off.}

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

  test "Fold operations":
    let lst = lc[x|(x <- 1..4),int].asList

    check: lst.foldLeft(0, (x: int, y: int) => x + y) == 10
    check: lst.foldLeft(1, (x: int, y: int) => x * y) == 24

    check: lst.foldRight(0, (x: int, y: int) => x + y) == 10
    check: lst.foldRight(1, (x: int, y: int) => x * y) == 24

  test "Drop operations":
    let lst = lc[x|(x <- 1..100),int].asList

    check: lst.drop(99) == [100].asList
    check: lst.dropWhile((x: int) => x < 100) == [100].asList

  test "Misc functions":
    let lst = lc[$x | (x <- 'a'..'z'), string].asList
    # Next two lines are so ugly because of https://github.com/nim-lang/Nim/issues/3313
    let lstEq = lst.dup == lst
    check: lstEq
    check: lst.reverse == lc[$(('z'.int - x).char) | (x <- 0..('z'.int - 'a'.int)), string].asList
    check: asList(2, 4, 6, 8).forAll((x: int) => x mod 2 == 0) == true
    check: asList(2, 4, 6, 9).forAll((x: int) => x mod 2 == 0) == false

  test "Iterator":
    let lst1 = [1, 2, 3, 4, 5].asList
    var lst2 = Nil[int]()
    for x in lst1:
      lst2 = Cons(x, lst2)
    check: lst2 == lst1.reverse
