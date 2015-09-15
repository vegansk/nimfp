import ../../src/fp/Option, unittest, future

{.warning[TypelessParam]: off.}

suite "Option ADT":

  test "Basic functions":
    let s = "test".some
    let n = int.none

    check: $s == "Some(test)"
    check: $n == "None"
    check: s.isEmpty == false
    check: s.isDefined == true
    check: n.isDefined == false
    check: n.isEmpty == true
    check: s == Some("test")
    check: s != string.none
    check: n == None[int]()

  test "Map":
    check: 100500.some.map((x: int) => $x) == some("100500")
    check: 100500.none.map((x: int) => $x) == string.none

