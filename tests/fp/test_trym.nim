import unittest,
       fp.trym,
       fp.either,
       future

suite "Try type":
  test "Initialization":
    check: 1.success.isSuccess == true
    check: newException(Exception, "Oops").failure(int).isFailure == true
    check: "Oops".failure(int).isFailure == true

  test "Conversion":
    let x1 = fromEither tryST do:
      "test"
    check: x1.isSuccess and x1.get == "test"
    let x2 = fromEither tryST do:
      "test".left(string)
    check: x2.isFailure and x2.getErrorMessage == "test"
    proc testProc: int =
      raise newException(Exception, "test")
    let x3 = fromEither tryET do:
      testProc()
    check: x3.isFailure and x3.getErrorMessage == "test"

  test "Recover":
    check: "test".failure(string).recover(e => e.msg) == "test".success
    let x = "test".failure(string).recoverWith(e => (e.msg & "1").failure(string))
    check: x.isFailure and x.getErrorMessage == "test1"

  test "Control structures":
    let x1 = tryM do:
      1
    check: x1.isSuccess and x1.get == 1
    let x2 = tryM do:
      discard
    check: x2.isSuccess and x2.get == ()
    let x3 = join tryM do:
      1.success
    check: x3.isSuccess and x3.get == 1
    let x4 = join tryM do:
      "Oops".failure(int)
    check: x4.isFailure and x4.getErrorMessage == "Oops"
