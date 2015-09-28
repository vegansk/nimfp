import ../../src/fp/either, unittest, future

{.warning[SmallLshouldNotBeUsed]: off.}

suite "Either ADT":

  test "Basic functions":
    let l1 = Left[int,string](10)
    let l2 = 10.left("")
    let l3 = 10.left(string)
    let r1 = Right[int,string]("test")
    let r2 = "test".right(0)
    let r3 = "test".right(int)

    check: l1 == l2
    check: l1 == l2

    check: r1 == r2
    check: r1 == r3

    check: r1 != l1
    check: r2 != l2

    check: 123.rightE == 123.rightE
    check: 123.rightS == 123.rightS

    check: $l1 == "Left(10)"
    check: $r1 == "Right(test)"
    
  test "Map":
    let r = 10.rightS
    let l = "Error".left(int)
    check: r.map(x => x * 2) == 20.rightS
    check: l.map(x => x * 2) != 20.rightS
    check: l.map(x => x * 2) == l

    check: r.flatMap((x: int) => (x * 2).rightS) == 20.rightS
    check: r.flatMap((x: int) => l) == l
