import unittest,
       fp

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
