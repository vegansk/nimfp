import unittest, fp/option

from fp/forcomp import act

## make sure act macro doesn't require having fc in
## instantiation context (matters for templates and generics)

suite "Symbol binding in act":
  test "ForComp - act should not require additional imports":
    let success = compiles:
      act:
       x <- 1.some
       x.some

    check success
