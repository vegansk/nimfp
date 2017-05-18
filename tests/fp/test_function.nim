import unittest,
       future,
       fp.function,
       fp.list,
       fp.forcomp

suite "Functions":

  test "Memoization":
    var x = 0
    let f = () => (inc x; x)
    let fm = f.memoize

    check: f() == 1
    check: f() == 2
    check: fm() == 3
    check: f() == 4
    check: fm() == 3

  test "Curried functions":
    let f2 = (x: int, y: int) => x + y
    check: f2.curried()(1)(2) == 3
    check: f2.curried().uncurried2()(1, 2) == 3
    check: asList(1,2,3,4).map(f2.curried()(1)) == asList(2,3,4,5)

    let f3 = (x: int, y: int, z: int) => x + y + z
    check: f3.curried()(1)(2)(3) == 6
    check: f3.curried1()(1)(2, 3) == 6
    check: f3.curried1()(1).curried()(2)(3) == 6
    check: f3.curried().uncurried2()(1, 2)(3) == 6
    check: f3.curried().uncurried3()(1, 2, 3) == 6

    let f4 = (a: int, b: int, c: int, d: int) => a + b + c + d
    check: f4.curried()(1)(2)(3)(4) == 10
    check: f4.curried1()(1)(2,3,4) == 10

  test "Composition":
    check: (((x: int) => x * 2) <<< ((x: int) => x + 1))(1) == 4
    check: (((x: int) => x * 2) >>> ((x: int) => x + 1))(1) == 3

  test "Flip":
    let f2 = (x: string, y: int) => x & $y
    let f3 = (x: string, y: int, z: string) => x & $y & z
    check: f2.flip()(1, "a") == "a1"
    check: f2.curried().flip()(1)("a") == "a1"
    # Now it's not working, need to invertigate why
    # check: f3.curried().flip()(1)("a")("b") == "a1b"
    # check: f3.curried()("a").flip()("b")(1) == "a1b"
    # check: f3.curried().flip().uncurried3()(1, "a", "b") == "a1b"

  test "Generics":
    proc mkList[T](v: T, i: int): List[T] =
      if i <= 0: Nil[T]()
      else: v ^^ mkList(v, i - 1)

    let ones = mkList[int].curried()(1)
