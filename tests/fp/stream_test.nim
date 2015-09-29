import ../../src/fp/stream, ../../src/fp/option, future, unittest

suite "Stream":

  test "Initialization":
    let sInt = [1, 2, 3, 4, 5].asStream

    check: $sInt == "Stream(1, 2, 3, 4, 5)"
    check: sInt.toSeq == lc[x | (x <- 1..5), int]
    check: sInt.isEmpty == false

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
