import future, unittest, ../../src/fp/option, ../../src/fp/either, ../../src/fp/list, macros

suite "ForComp":
  test "ForComp - Option - manual":
    # for (x <- 1.some, y <- x + 3) yield y * 100
    check: 1.some.flatMap((x: int) => (x + 3).some).map(y => y * 100) == 400.some
    check: 1.some.flatMap((x: int) => (x + 3).some).flatMap((y: int) => (y * 100).some) == 400.some
    check: 1.some.flatMap((x: int) =>
      (x + 3).some.flatMap((y: int) =>
        (y * 100).some
      )
    ) == 400.some
    # for (x <- 1.some, y <- 2.some, doSomething(), z <- y * 3) yield x + y + z
    let doSomething = () => 100500.some
    check: 1.some.flatMap((x: int) =>
      2.some.flatMap((y: int) =>
        doSomething().flatMap((_: int) =>
          (y * 3).some.flatMap((z: int) =>
            (x + y + z).some
          )
        )
      )
    ) == 9.some
    
#Syntax 1:
dumpTree:
  fc[(x + y + z).some | (
    (x: int) <- 1.some,
    (y: int) <- 2.some,
    (_: int) <- doSomething(),
    (z: int) <- (y * 3).some
  )]
# Syntax 2:
