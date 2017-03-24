import unittest,
       fp,
       future,
       boost.types

suite "Future":
  test "Initialization":
    let x1 = future do:
      1
    check: x1.value.isEmpty
    discard run x1
    check: x1.value.isDefined
    check: x1.value.get.isSuccess
    check: x1.value.get.get == 1
    let x2 = newFuture do() -> auto:
      block:
        raise newException(Exception, "Oops")
      1
    check: x2.value.isEmpty
    discard run x2
    check: x2.value.isDefined
    check: x2.value.get.isFailure
    check: x2.value.get.getErrorMessage == "Oops"

    let x3 = newFuture[void]()
    x3.complete
    check: x3.value.isDefined
    check: x3.value.get.isSuccess
    check: x3.value.get.get == ()

  test "Do notation":
    let y1 = act do:
      x <- future(3)
      yield x * 2
    let res1 = run y1
    check: res1.get == 6

    let y2 = act do:
      x <- newFuture do() -> auto:
        block:
          raise newException(Exception, "Oops")
        3
      yield x * 2
    expect(Exception):
      discard y2.run.get

  test "Future[void] support":
    check unit[void]().map(_ => 1).run.get == 1
    check unit[void]().flatMap((_: Unit) => unit(1)).run.get == 1
    check unit[void]().elemType is Unit

  test "Utilities":
    let x1 = future(future(1))
    check: x1.join.run.get == 1

    let x2 = future(1.success)
    check: x2.flattenF.run.get == 1

    let x3 = future("Oops".failure(int))
    check: x3.flattenF.run.getErrorMessage == "Oops"

    var res = 1
    var x4 = future(2)
    x4.onComplete((v: Try[int]) => (res = v.get))
    discard x4.run
    check: res == 2

    check: sleepAsync(200).map(_ => 1).timeout(100).run.get == int.none
    check: sleepAsync(100).map(_ => 1).timeout(200).run.get == 1.some
