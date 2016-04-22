import macros, strutils, sequtils

type ForComprehension = distinct object

var fc*: ForComprehension

macro `[]`*(fc: ForComprehension, comp: expr): expr =
  ## For comprehension with list comprehension like syntax.
  ## Example:
  ## 
  ## .. code-block:: nim
  ##   
  ##   let res = fc[(y*100).some | (
  ##     (x: int) <- 1.some,
  ##     (y: int) <- (x + 3).some
  ##   )]
  ##   assert(res == 400.some)
  ##
  ## The only requirement for the user is to implement `foldMap`` function for the type
  ## 
  expectLen(comp, 3)
  expectKind(comp, nnkInfix)
  expectKind(comp[0], nnkIdent)
  assert($comp[0].ident == "|")

  result = comp[1]

  for i in countdown(comp[2].len-1, 0):
    var x = comp[2][i]
    if x.kind != nnkInfix or $x[0] != "<-":
      x = newNimNode(nnkInfix).add(ident"<-").add(ident"_").add(x)
    expectLen(x, 3)
    var iDef: NimNode
    var iType: NimNode
    if x[1].kind == nnkIdent:
      iDef = x[1]
      iType = newCall(ident"elemType", x[2])
    else:
      expectLen(x[1], 1)
      expectMinLen(x[1][0], 2)
      expectKind(x[1][0][0], nnkIdent)
      iDef = x[1][0][0]
      iType = x[1][0][1]
    let cont = x[2]
    let lmb = newProc(params = @[ident"auto", newIdentDefs(iDef, iType)], body = result, procType = nnkLambda)
    let p = newNimNode(nnkPragma)
    p.add(ident"closure")
    lmb[4] = p
    result = quote do:
      `cont`.flatMap(`lmb`)

macro act*(comp: untyped): expr =
  ## For comprehension with Haskell ``do notation`` like syntax.
  ## Example:
  ## 
  ## .. code-block:: nim
  ##   
  ##   let res = act do:
  ##     (x: int) <- 1.some,
  ##     (y: int) <- (x + 3).some
  ##     (y*100).some
  ##   assert(res == 400.some)
  ##
  ## The only requirement for the user is to implement `foldMap`` function for the type
  ## 
  expectKind comp, {nnkStmtList, nnkDo}
  let stmts = if comp.kind == nnkStmtList: comp else: comp.findChild(it.kind == nnkStmtList)
  expectMinLen(stmts, 2)
  result = newNimNode(nnkBracketExpr)
  result.add(ident"fc")
  block:
    let op = newNimNode(nnkInfix)
    result.add(op)
    op.add(ident"|")
    op.add(stmts[stmts.len-1].copyNimTree)
    let par = newNimNode(nnkPar)
    op.add(par)
    for i in 0..<(stmts.len-1):
      par.add(stmts[i].copyNimTree)
