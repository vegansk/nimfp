import ../../src/fp/functions, unittest, future

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
