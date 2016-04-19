import future, unittest, ../../src/fp/option, ../../src/fp/either, ../../src/fp/list, ../../src/fp/forcomp, macros

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

  test "ForComp - Option - fc macro":
    # for (x <- 1.some, y <- x + 3) yield y * 100
    check: fc[(y*100).some | (
      (x: int) <- 1.some,
      (y: int) <- (x + 3).some
    )] == 400.some
    check: fc[(y*100).some | (
      (x: int) <- int.none,
      (y: int) <- (x + 3).some
    )] == int.none

  test "ForComp - Either - fc macro":
    # for (x <- 1.rightS, y <- x + 3) yield y * 100
    check: fc[(y*100).rightS | (
      (x: int) <- 1.rightS,
      (y: int) <- (x + 3).rightS
    )] == 400.rightS
    
    check: fc[(y*100).rightS | (
      (x: int) <- "Fail".left(int),
      (y: int) <- (x + 3).rightS
    )] == "Fail".left(int)
    
  test "ForComp - Option - act macro":
    # for (x <- 1.some, y <- x + 3) yield y * 100
    let res = act do:
      (x: int) <- 1.some
      (y: int) <- (x + 3).some
      (y*100).some
    check: res == 400.some
    let res2 = act do:
      (x: int) <- int.none
      (y: int) <- (x + 3).some
      (y*100).some
    check: res2 == int.none
    
  test "ForComp - Either - act macro":
    # for (x <- 1.rightS, y <- x + 3) yield y * 100
    let res = act do:
      (x: int) <- 1.rightS
      (y: int) <- (x + 3).rightS
      (y*100).rightS
    check: res == 400.rightS
    let res2 = act do:
      (x: int) <- "Fail".left(int)
      (y: int) <- (x + 3).rightS
      (y*100).rightS 
    check: res2 == "Fail".left(int)

  test "ForComp - ``if`` example":
    proc testFunc(i: int): Option[int] = act:
      (x: int) <- (if i < 10: int.none else: i.some)
      (x * 100).some

    check: testFunc(1).isDefined == false
    check: testFunc(20) == 2000.some

  test "ForComp - crash test":
    proc io1(): EitherS[int] =
      1.rightS
    proc io2(i: int): EitherS[string] =
      ("From action 2: " & $i).rightS
    proc io3(i: int, s: string): EitherS[string] =
      ("Got " & $i & " from aсtion 1 and '" & s & "' from action 2").rightS
    let res = fc[io3(i, s) | ((i: int) <- io1(), (_: tuple[]) <- (echo("i = ", i); ().rightS), (s: string) <- io2(i), (_: tuple[]) <- (echo("s = ", s); ().rightS))]

    echo res
    
#Syntax 1:
# dumpTree:
#   fc[(x + y + z).some | (
#     (x: int) <- 1.some,
#     (y: int) <- 2.some,
#     (_: int) <- doSomething(),
#     (z: int) <- (y * 3).some
#   )]
# Syntax 2:
# dumpTree:
#   let x = forc do:
#     (x: int) <- 1.some
#     (y: int) <- 2.some
#     (_: int) <- doSomething()
#     (z: int) <- (y * 3).some
#     (x + y + z).some
