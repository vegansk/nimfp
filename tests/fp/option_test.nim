import ../../src/fp/option, unittest, future

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
    let f = (x: int) => $x
    check: 100500.some.map(f) == some("100500")
    check: 100500.none.map(f) == string.none

  test "Flat map":
    let f = (x: int) => some(x * 2)
    check: 2.some.flatMap(f) == some(4)
    check: 2.none.flatMap(f) == none(4)

  test "Getters":
    check: 2.some.getOrElse(3) == 2
    check: 2.none.getOrElse(3) == 3

    check: 2.some.getOrElse(() => 4) == 2
    check: 2.none.getOrElse(() => 4) == 4

    check: 2.some.orElse(3.some) == 2.some
    check: 2.none.orElse(3.some) == 3.some
    
    check: 2.some.orElse(() => 4.some) == 2.some
    check: 2.none.orElse(() => 4.some) == 4.some

  test "Filter":
    let x = "123".some
    let y = "12345".some
    let n = "".none
    let p = (x: string) => x.len > 3
    proc `!`[T](f: T -> bool): T -> bool = (x: T) =>  not f(x)

    check: x.filter(p) == n
    check: x.filter(!p) == x
    check: y.filter(p) == y
    check: y.filter(!p) == n
    check: n.filter(p) == n
    check: n.filter(!p) == n
