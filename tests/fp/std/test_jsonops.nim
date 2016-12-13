import unittest,
       future,
       fp,
       json

suite "std.json":

  let doc = """
{
  "int": 123,
  "str": "Hello!",
  "bool": true,
  "obj": {
    "int": 20
  }
}
""".parseJson

  test "mget":
    check: doc.mget("int").get.isDefined
    check: doc.mget("int2").get.isEmpty
    let v = doc.some.rightS >>= (mget("obj") >=> mget("int"))
    check: v.get.isDefined

  test "value":
    check: value(int, doc["int"]) == 123.rightS
    check: value(string, doc["int"]).isLeft
    check: value(string, doc["str"]) == "Hello!".rightS
    check: value(int, doc["str"]).isLeft
    check: doc.some.rightS >>= (
      mget("obj") >=>
      mget("int") >=>
      mvalue(int)
    ) == 20.some.rightS
    check: value(bool, doc["bool"]) == true.rightS
