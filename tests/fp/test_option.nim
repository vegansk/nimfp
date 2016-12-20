import ../../src/fp/option, unittest, future

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
    check: "".some.notNil == "".some
    check: nil.string.some.notNil == "".none
    check: "".none.notNil == "".none
    check: " 123 ".some.notEmpty == " 123 ".some
    check: "  ".some.notEmpty == "".none
    check: "123".none.notEmpty == "".none
    check: nil.string.some.notEmpty == "".none

    check: (2 < 3).optionF(() => true).getOrElse(false)
    check: (2 < 3).option(true).getOrElse(false)

    check: s.get == "test"
    expect(AssertionError): discard n.get == 10

    check: 1.point(Option) == 1.some

  test "Map":
    let f = (x: int) => $x
    check: 100500.some.map(f) == some("100500")
    check: 100500.none.map(f) == string.none

    check: 100.some.map2("Test".some, (x, y) => y & $x) == "Test100".some
    check: 100.some.map2("Test".none, (x, y) => y & $x) == "".none

    check: 100.some.map2F(() => "Test".some, (x, y) => y & $x) == "Test100".some
    check: 100.some.map2F(() => "Test".none, (x, y) => y & $x) == "".none

    proc badOption(): Option[int] = raise newException(Exception, "Not lazy!")
    check: int.none.map2F(badOption, (x, y) => $x) == string.none

    check: "x".some.map(v => "\"" & v & "\"").getOrElse("y") == "\"x\""
    check: "x".none.map(v => "\"" & v & "\"").getOrElse("y") == "y"

  test "Flat map":
    let f = (x: int) => some(x * 2)
    check: 2.some.flatMap(f) == some(4)
    check: 2.none.flatMap(f) == none(4)

  test "Join":
    check: 2.some.some.join == 2.some
    check: int.none.some.join == int.none
    check: Option[int].none.join == int.none

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
    proc `!`[T](f: T -> bool): T -> bool = (v: T) => not f(v)

    check: x.filter(p) == n
    check: x.filter(!p) == x
    check: y.filter(p) == y
    check: y.filter(!p) == n
    check: n.filter(p) == n
    check: n.filter(!p) == n

  test "Traverse":
    let a = @[1, 2, 3]

    let f1 = (t: int) => (t - 1).some
    check: traverse(a, f1) == @[0, 1, 2].some

    let f2 = (t: int) => (if (t < 3): t.some else: int.none)
    check: traverse(a, f2) == seq[int].none

  test "Misc":
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

    check: 1.some.zip("foo".some) == (1, "foo").some
    check: 1.some.zip(string.none) == (int, string).none

    check: 1.some.asSeq == @[1]
    check: int.none.asSeq == newSeq[int]()

  test "Kleisli":
    let f = (v: int) => (v + 1).some
    let g = (v: int) => (v * 100).some
    check: 4.some >>= (f >=> g) == 500.some

