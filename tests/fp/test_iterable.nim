import unittest,
       fp

suite "Iterable":
  test "flatten":
    check: [1.some, int.none, 2.some].asList.flatten == [1, 2].asList
    check: [1.rightS, "".left(int), 2.rightS].asList.flatten == [1, 2].asList
    check: [[1].asList, Nil[int](), [2].asList].asList.flatten == [1, 2].asList
