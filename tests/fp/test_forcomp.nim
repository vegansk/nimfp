import future, unittest, ../../src/fp/option, ../../src/fp/either, ../../src/fp/list, ../../src/fp/forcomp, macros, ../../src/fp/stream

suite "ForComp":
  test "Option - manual":
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

  test "Option - fc macro":
    # for (x <- 1.some, y <- x + 3) yield y * 100
    check: fc[(y*100).some | (
      (x: int) <- 1.some,
      (y: int) <- (x + 3).some
    )] == 400.some
    check: fc[(y*100).some | (
      (x: int) <- int.none,
      (y: int) <- (x + 3).some
    )] == int.none

  test "Either - fc macro":
    # for (x <- 1.rightS, y <- x + 3) yield y * 100
    check: fc[(y*100).rightS | (
      (x: int) <- 1.rightS,
      (y: int) <- (x + 3).rightS
    )] == 400.rightS
    
    check: fc[(y*100).rightS | (
      (x: int) <- "Fail".left(int),
      (y: int) <- (x + 3).rightS
    )] == "Fail".left(int)
    
  test "Option - act macro":
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
    
  test "Either - act macro":
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

  test "``if`` example":
    proc testFunc(i: int): Option[int] = act:
      (x: int) <- (if i < 10: int.none else: i.some)
      (x * 100).some

    check: testFunc(1).isDefined == false
    check: testFunc(20) == 2000.some

  test "Lists":
    let res = act do:
      (x: int) <- asList(1,2,3)
      (y: int) <- asList(1,2,3)
      asList((x, y))
    echo res

  test "Type inference":
    let res = act do:
      x <- asList(1,2,3)
      y <- asList("a", "b", "c")
      asList(y & $x)
    echo res

    let resO = act do:
      x <- 1.some
      y <- (x * 2).some
      ().none
      ("res = " & $y).some
    echo resO

  test "Crash test":
    proc io1(): EitherS[int] =
      1.rightS
    proc io2(i: int): EitherS[string] =
      ("From action 2: " & $i).rightS
    proc io3(i: int, s: string): EitherS[string] =
      ("Got " & $i & " from aсtion 1 and '" & s & "' from action 2").rightS
    let res = fc[io3(i, s) | (i <- io1(), (echo("i = ", i); ().rightS), s <- io2(i), (echo("s = ", s); ().rightS))]

    echo res

  test "Streams test":
    proc intStream(fr: int): Stream[int] =
      cons(() => fr, () => intStream(fr + 1))

    let res = act do:
      x <- intStream(1)
      asStream("S" & $x)

    echo res.take(10)

  test "Custom types":
    proc flatMap[T](s: seq[T], f: T -> seq[T]): seq[T] =
      result = newSeq[T]()
      for v in s:
        result.add(f(v))
    template elemType(s: seq): typedesc =
      type(s[0])

    let res = act do:
      x <- @[1, 2, 3]
      y <- @[100, 200, 300]
      z <- @[5, 7]
      @[x * y + z]

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
