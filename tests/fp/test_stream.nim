import ../../src/fp/stream, ../../src/fp/option, sugar, unittest

suite "Stream":

  test "Initialization":
    let sInt = [1, 2, 3, 4, 5].asStream

    check: $sInt == "Stream(1, 2, 3, 4, 5)"
    check: sInt.toSeq == lc[x | (x <- 1..5), int]
    check: sInt.isEmpty == false

    check: (() => 1).point(Stream).toSeq == @[1]

  test "Accessors":
    let sInt = [1, 2, 3, 4, 5].asStream

    check: sInt.head == 1
    check: sInt.headOption == 1.some
    check: sInt.tail == [2, 3, 4, 5].asStream

  test "Functions":
    let sInt = [1, 2, 3, 4, 5].asStream

    check: sInt.take(2) == [1, 2].asStream
    check: sInt.drop(2) == [3, 4, 5].asStream
    check: sInt.takeWhile(x => x < 3) == [1, 2].asStream
    check: sInt.dropWhile(x => x < 3) == [3, 4, 5].asStream
    check: sInt.forAll(x => x < 10) == true
    check: sInt.map(x => "Val" & $x) == lc[("Val" & $x) | (x <- 1..5), string].asStream
    check: sInt.filter(x => x mod 2 == 0) == [2, 4].asStream
    check: sInt.append(() => 100) == [1, 2, 3, 4, 5, 100].asStream
    check: sInt.flatMap((x: int) => cons(() => x, () => cons(() => x * 100, () => int.empty))) == [1, 100, 2, 200, 3, 300, 4, 400, 5, 500].asStream

  test "Check infinite streams":
    proc intStream(fr: int): Stream[int] =
      cons(() => fr, () => intStream(fr + 1))

    check: intStream(1).take(100) == lc[x | (x <- 1..100), int].asStream
    check: intStream(1).drop(100).take(100) == lc[x | (x <- 101..200), int].asStream
