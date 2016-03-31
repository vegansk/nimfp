import ../../src/fp/option, unittest, future

suite "Option ADT":

  test "Option - Basic functions":
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
    check: "".some.notNil == "".some
    check: nil.string.some.notNil == "".none
    check: "".none.notNil == "".none
    check: " 123 ".some.notEmpty == " 123 ".some
    check: "  ".some.notEmpty == "".none
    check: "123".none.notEmpty == "".none
    check: nil.string.some.notEmpty == "".none

    check: s.get == "test"
    expect(AssertionError): discard n.get == 10

  test "Option - Map":
    let f = (x: int) => $x
    check: 100500.some.map(f) == some("100500")
    check: 100500.none.map(f) == string.none
    check: 100.some.map2("Test".some, (x, y) => y & $x) == "Test100".some
    check: 100.some.map2("Test".none, (x, y) => y & $x) == "".none

    check: "x".some.map(v => "\"" & v & "\"").getOrElse("y") == "\"x\""
    check: "x".none.map(v => "\"" & v & "\"").getOrElse("y") == "y"

  test "Option - Flat map":
    let f = (x: int) => some(x * 2)
    check: 2.some.flatMap(f) == some(4)
    check: 2.none.flatMap(f) == none(4)

  test "Option - Getters":
    check: 2.some.getOrElse(3) == 2
    check: 2.none.getOrElse(3) == 3

    check: 2.some.getOrElse(() => 4) == 2
    check: 2.none.getOrElse(() => 4) == 4

    check: 2.some.orElse(3.some) == 2.some
    check: 2.none.orElse(3.some) == 3.some
    
    check: 2.some.orElse(() => 4.some) == 2.some
    check: 2.none.orElse(() => 4.some) == 4.some

  test "Option - Filter":
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

  test "Option - Misc":
    check: ((x: int) => "Value " & $x).liftO()(1.some) == "Value 1".some
    var b = true
    false.some.forEach((v: bool) => (b = v))
    check: b == false
    true.some.forEach((v: bool) => (b = v))
    check: b == true
    false.none.forEach((v: bool) => (b = v))
    check: b == true
    check: true.some.forAll(v => v) == true
    check: false.some.forAll(v => v) == false
    check: false.none.forAll(v => v) == true
