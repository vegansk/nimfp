import unittest, fp.option

from fp.forcomp import act

## make sure act macro doesn't require having fc in
## instantiation context (matters for templates and generics)

suite "Symbol binding in act":
  test "act should not require fc in instantiation context":
    let success = compiles(
      act do:
       (x: int) <- 1.some
       x.some
    )

    check success
