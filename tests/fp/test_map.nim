import ../../src/fp/option, ../../src/fp/map, ../../src/fp/list, unittest, sugar, strutils

suite "Map ADT":
  let m = [(1, "1"), (2, "2"), (3, "3")].asMap

  test "Initialization":
    check: m.asList == [(1, "1"), (2, "2"), (3, "3")].asList
    check: $m == "Map(1 => 1, 2 => 2, 3 => 3)"
    check: m.get(1) == "1".some
    check: m.get(2) == "2".some
    check: m.get(3) == "3".some
    check: m.get(4) == "4".none

  test "Transformations":
    check: (m + (4, "4")).get(4) == "4".some
    check: (m + (1, "11")).get(1) == "11".some
    check: (m - 1).get(1) == "11".none

    let r = m.map((i: (int,string)) => ($i.key, i.value.parseInt))
    check: r == [("3", 3), ("1", 1), ("2", 2)].asMap

    check: m.mapValues(v => v & v) == [(3, "33"), (1, "11"), (2, "22")].asMap

  test "Misc":
    var x = 0
    [(1, 100), (2, 200)].asMap.forEach((v: (int, int)) => (x += (x + v.key) * v.value))
    check: x == 20500
    check: map.find(m, v => (v[0] mod 2 == 0)) == (2, "2").some
    check: m.filter(v => (v[0] mod 2 == 0)) == [(2, "2")].asMap
    check: m.remove(1).get(1) == string.none
    check: m.map(i => (i[0] * 2, i[1] & i[1])) == [(2, "11"), (4, "22"), (6, "33")].asMap
    check: m.forAll(i => $i[0] == i[1])

  test "Equality":
    check: asMap((1, 2), (3, 4)) == asMap((3, 4), (1, 2))
    check: asMap((1, 2), (3, 4)) != asMap((1, 2))
    check: asMap((1, 2)) != asMap((1, 2), (3, 4))
    check: asMap((1, 2), (3, 4)) != asMap((3, 4), (1, 5))
