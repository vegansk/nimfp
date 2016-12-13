import ../../src/fp/list,
       ../../src/fp/either,
       ../../src/fp/option,
       unittest,
       future,
       boost.types,
       threadpool

{.warning[SmallLshouldNotBeUsed]: off.}

suite "Either ADT":

  let r = 10.rightS
  let l = "Error".left(int)

  test "Basic functions":
    let l1 = Left[int,string](10)
    let l2 = 10.left("")
    let l3 = 10.left(string)
    discard l3
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

    check: r1.get == "test"
    expect(AssertionError): discard l1.get == "test"

    check: either.cond(true, 1, 0) == 1.right(int)
    check: either.cond(false, 1, 0) == 0.left(int)
    check: either.condF(true, () => 1, () => 0) == 1.right(int)
    check: either.condF(false, () => 1, () => 0) == 0.left(int)

    check: 1.some.asEither("nope") == 1.rightS
    check: 1.none.asEither("nope") == "nope".left(int)

    check: "Error".left(int).asEitherE.getLeft.msg == "Error"
    check: newException(Exception, "Error").left(int).asEitherS.getLeft == "Error"

    check: 1.rightS.asOption == 1.some
    check: ().left(int).asOption == none(int)

    check: 1.rightS.flip == 1.left(string)
    check: 1.left(string).flip == 1.rightS

    check: 1.rightS.toUnit == ().rightS

    check: 1.rightS.rightS.join == 1.rightS
    check: "error".left(1.rightS).join == "error".left(int)
    check: ("error".left(int)).rightS.join == "error".left(int)

    check: 1.point(EitherS[int]) == 1.rightS
    check: 1.point(EitherE[int]) == 1.rightE

  test "Map":
    check: r.map(x => x * 2) == 20.rightS
    check: l.map(x => x * 2) != 20.rightS
    check: l.map(x => x * 2) == l

    check: 1.rightS.mapLeft(_ => 404) == 1.right(int)
    check: "Error".left(int).mapLeft(_ => 404) == 404.left(int)

    check: r.flatMap((x: int) => (x * 2).rightS) == 20.rightS
    check: r.flatMap((x: int) => l) == l

    check: "Value".rightS.map2(10.rightS, (x: string, y: int) => x & $y) == "Value10".rightS
    check: "Error1".left(string).map2(10.rightS, (x: string, y: int) => x & $y) == "Error1".left(string)
    check: "Value".rightS.map2("Error2".left(int), (x: string, y: int) => x & $y) == "Error2".left(string)
    check: 10.rightS.map2("Error2".left(int), (x: int, y: int) => x + y) == "Error2".left(int)

    check: "Value".rightS.map2F(() => 10.rightS, (x: string, y: int) => x & $y) == "Value10".rightS
    check: "Error1".left(string).map2F(() => 10.rightS, (x: string, y: int) => x & $y) == "Error1".left(string)
    check: "Value".rightS.map2F(() => "Error2".left(int), (x: string, y: int) => x & $y) == "Error2".left(string)
    check: 10.rightS.map2F(() => "Error2".left(int), (x: int, y: int) => x + y) == "Error2".left(int)

    proc badEither(): EitherS[int] = raise newException(Exception, "Not lazy!")
    check: "err".left(string).map2F(badEither, (x, y) => x & $y) == "err".left(string)

  test "Getters":
    check: r.getOrElse(0) == 10
    check: r.getOrElse(() => 0) == 10

    check: l.getOrElse(0) == 0
    check: l.getOrElse(() => 0) == 0

    check: r.orElse(l) == r
    check: r.orElse(() => l) == r

    check: l.orElse(r) == r
    check: l.orElse(() => r) == r

  test "Safe exceptions":
    check: tryE(() => 2/4) == 0.5.rightE
    check: tryS(() => 2/4) == 0.5.rightS
    {.floatChecks: on.}
    var x = 2.0
    check: tryE(() => x / 0.0).isLeft == true
    check: tryS(() => x / 0.0).isLeft == true
    let f = () => (
      result = 1;
      raise newException(Exception, "Test Error")
    )
    let ex1 = tryS f
    let ex2 = tryE f
    check: ex1.errorMsg == "Test Error"
    check: ex2.errorMsg == "Test Error"

    let g1 = () => "Error 1".left(());
    let g2 = () => (
      result = ().rightE;
      raise newException(Exception, "Error 2")
    )
    check: g1.flatTryS.errorMsg == "Error 1"
    check: g2.flatTryE.errorMsg == "Error 2"

  test "Transformations":
    let good = @[1, 2, 3, 4, 5].asList
    let goodE = @[1, 2, 3, 4, 5].asList.map(x => x.rightS)
    let badE = @[1, 2, 3, 4].asList.map(x => x.rightS) ++ @["Error".left(int)].asList

    check: good.traverse((x: int) => x.rightS) == good.rightS
    check: good.traverse((x: int) => (if x < 3: x.rightS else: "Error".left(type(x)))) == "Error".left(List[int])
    check: goodE.sequence == good.rightS
    check: badE.sequence == "Error".left(List[int])

    # traverse should not call f after the first Left
    var cnt = 0
    let res = asList(1, 2, 3).traverse do (x: int) -> auto:
      inc cnt
      if x != 2: x.rightS
      else: "err".left(int)
    check: res == "err".left(List[int])
    check: cnt == 2

    # Traverse with Option
    proc leftFunc(i: int): EitherS[bool] = "foo".left(bool)
    proc rightFunc(i: int): EitherS[bool] = true.rightS
    check: int.none.traverse(rightFunc) == bool.none.rightS
    check: int.none.traverse(leftFunc) == bool.none.rightS
    check: 1.some.traverse(rightFunc) == true.some.rightS
    check: 1.some.traverse(leftFunc) == "foo".left(Option[bool])

  test "Traverse with List should allow to properly infer gcsafe":
    proc f(i: int): auto = i.rightS

    proc g(): auto {.gcsafe.} =
      asList(1, 2, 3).traverse(f)

    discard g()

  test "Control flow":
    check: whenF(true, () => "error".left(Unit)) == "error".left(Unit)
    check: whenF(false, () => "error".left(Unit)) == ().rightS

    let whileRes = whileM(10) do (v: int) -> auto:
      (v > 0).rightS
    do (v: int) -> auto:
      (v - 1).rightS
    check: whileRes == 0.rightS
    check: whileM("error", (v: string) => v.left(bool), (v: string) => v.rightS) == "error".left(string)

    # whileM - convenience wrapper
    var iters = 0
    let whileRes2 = whileM() do () -> auto:
      (iters < 3).rightS
    do () -> auto:
      iters.inc
      ().rightS
    check: whileRes2 == ().rightS
    check: iters == 3

    check: 1.rightE.run == 1
    expect(ValueError):
      discard newException(ValueError, "error").left(int).run

    const sres = "Hello, world!"
    let bres = bracket do () -> auto:
      cast[ptr array[100, char]](allocShared(100)).rightS
    do (s: ptr array[100, char]) -> auto:
      deallocShared(cast[pointer](s))
      ().rightS
    do (s: ptr array[100, char]) -> auto:
      proc thr(p: pointer) {.thread.} =
        copyMem(p, sres.cstring, sres.len + 1)
      var t: Thread[pointer]
      createThread(t, thr, s)
      t.joinThread
      ($s[]).rightS
    check: bres.run == sres

    let eres = "Exception".left(int).catch do (s: string) -> auto:
      1.rightE
    check: eres == 1.rightE

  test "Kleisli ops":
    let f = (v: int) => (v + 1).rightS
    let g = (v: int) => (v * 100).rightS
    check: 4.rightS >>= (f >=> g) == 500.rightS

