import ../../src/fp/List, unittest, future

{.warning[TypelessParam]: off.}

suite "List ADT":

  test "Initialization and conversion":
    let lst = [1, 2, 3, 4, 5].asList

    check: lst.head == 1
    check: lst.tail.asSeq == @[2, 3, 4, 5]
    check: $lst == "List(1, 2, 3, 4, 5)"
    check: 1^^2^^3^^4^^5^^Nil[int]() == lst
    check: ["a", "b"].asList != ["a", "b", "c"].asList

  test "Fold operations":
    let lst = lc[x|(x <- 1..4),int].asList

    check: lst.foldLeft(0, (x, y) => x + y) == 10
    check: lst.foldLeft(1, (x, y) => x * y) == 24

    check: lst.foldRight(0, (x, y) => x + y) == 10
    check: lst.foldRight(1, (x, y) => x * y) == 24

  test "Drop operations":
    let lst = lc[x|(x <- 1..100),int].asList

    check: lst.drop(99) == [100].asList
    check: lst.dropWhile(x => x < 100) == [100].asList

  test "Misc functions":
    let lst = lc[$x | (x <- 'a'..'z'), string].asList
    # Next two lines are so ugly because of https://github.com/nim-lang/Nim/issues/3313
    let lstEq = lst.dup == lst
    check: lstEq
    check: lst.reverse == lc[$(('z'.int - x).char) | (x <- 0..('z'.int - 'a'.int)), string].asList
