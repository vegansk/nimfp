import ../../src/fp/option, ../../src/fp/map, ../../src/fp/list, unittest, future, strutils

suite "Map ADT":
  let m = [(1, "1"), (2, "2"), (3, "3")].asMap

  test "Map - Initialization":
    check: $m == "Map(1 => 1, 2 => 2, 3 => 3)"
    check: m.get(1) == "1".some
    check: m.get(2) == "2".some
    check: m.get(3) == "3".some
    check: m.get(4) == "4".none

  test "Map - Transformations":
    check: (m + (4, "4")).get(4) == "4".some
    check: (m + (1, "11")).get(1) == "11".some
    check: (m - 1).get(1) == "11".none

    let r = m.map((i: (int,string)) => ($i.key, i.value.parseInt))
    check: r == [("3", 3), ("1", 1), ("2", 2)].asMap

  test "Map - Misc":
    var x = 0
    [(1, 100), (2, 200)].asMap.forEach((v: (int, int)) => (x += (x + v.key) * v.value))
    check: x == 20500
