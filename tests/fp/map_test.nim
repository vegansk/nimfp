import ../../src/fp/option, ../../src/fp/map, ../../src/fp/list, unittest, future

suite "Map ADT":
  test "Initialization":
    let m = [(1, "1"), (2, "2"), (3, "3")].asMap
    let l = [(1, "1"), (2, "2"), (3, "3")].asList
    echo m
    echo l
    check: $m == "Map(1 => 1, 2 => 2, 3 => 3)"
    check: m.get(1) == "1".some
    check: m.get(2) == "2".some
    check: m.get(3) == "3".some
