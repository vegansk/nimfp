import future,
       unittest,
       macros,
       ../../src/fp/option,
       ../../src/fp/either,
       ../../src/fp/list,
       ../../src/fp/forcomp,
       ../../src/fp/trym,
       ../../src/fp/stream

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
    let res = act:
      (x: int) <- 1.some
      (y: int) <- (x + 3).some
      (y*100).some
    check: res == 400.some
    let res2 = act:
      (x: int) <- int.none
      (y: int) <- (x + 3).some
      (y*100).some
    check: res2 == int.none

  test "Either - act macro":
    # for (x <- 1.rightS, y <- x + 3) yield y * 100
    let res = act:
      (x: int) <- 1.rightS
      (y: int) <- (x + 3).rightS
      (y*100).rightS
    check: res == 400.rightS
    let res2 = act:
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
    let res = act:
      (x: int) <- asList(1,2,3)
      (y: int) <- asList(1,2,3)
      asList((x, y))
    echo res

  test "Type inference":
    let res = act:
      x <- asList(1,2,3)
      y <- asList("a", "b", "c")
      asList(y & $x)
    echo res

    let resO = act:
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
    let res = act:
      x <- intStream(1)
      asStream("S" & $x)
    check: res.take(10).asList == lc[i | (i <- 1..10), int].asList.map(v => "S" & $v)

  test "Custom types":
    proc flatMap[T](s: seq[T], f: T -> seq[T]): seq[T] =
      result = newSeq[T]()
      for v in s:
        result.add(f(v))
    template elemType(s: seq): typedesc =
      type(s[0])

    let res = act:
      x <- @[1, 2, 3]
      y <- @[100, 200, 300]
      z <- @[5, 7]
      @[x * y + z]

    check: res == @[105, 107, 205, 207, 305, 307, 205, 207, 405, 407, 605, 607, 305, 307, 605, 607, 905, 907]

  test "act in generics":
    # https://github.com/nim-lang/Nim/issues/4669
    proc foo[A](a: A): Option[A] =
      act:
        a0 <- a.some
        a0.some

    assert: foo("123") == "123".some

  test "Yield in do notation":
    let res = act:
      x <- 1.some
      y <- 2.some
      z <- 3.some
      yield x + y + z
    check: res == 6.some

  test "Misc syntax support":
    proc test(x: int): int = x
    let res = act:
      a <- tryM(test(1))
      b <- tryM: test(3)
      c <- tryM do:
        let x = test(5)
        x
      d <- tryM test(7)
      tryM do:
        # void can also be used
        discard test(0)
      yield a + b + c + d
    check: res == success(16)

  test "AST change #1":
    proc pos(x: int): Option[int] = act:
      y <- (if x < 0: int.none else: x.some)
      z <- act:
        x <- (if y == 0: int.none else: y.some)
        yield x
      yield z

    check: pos(1) == 1.some

  test "AST change #2":
    let x = act:
      v <- tryS do () -> auto:
        1
      yield v
    check: x == 1.rightS
