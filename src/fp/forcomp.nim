import macros, strutils, sequtils

type ForComprehension = distinct object
type ForComprehensionYield = distinct object

var fc*: ForComprehension

proc parseExpression(node: NimNode): NimNode {.compileTime.} =
  if node.len == 3:
    return node[2]
  elif node.len == 4 and
       node[2].kind == nnkIdent and
       node[3].kind in {nnkStmtList, nnkDo}:
    return newNimNode(
      nnkCall
    ).add(node[2]).add(node[3])
  else:
    echo node.toStrLit
    echo treeRepr(node)
    error("Can't create expression from node", node)

proc forCompImpl(yieldResult: bool, comp: NimNode): NimNode {.compileTime.} =
  expectLen(comp, 3)
  expectKind(comp, nnkInfix)
  expectKind(comp[0], nnkIdent)
  assert($comp[0].ident == "|")

  result = comp[1]
  var yieldNow = yieldResult

  for i in countdown(comp[2].len-1, 0):
    var x = comp[2][i]
    if x.kind != nnkInfix or $x[0] != "<-":
      x = newNimNode(nnkInfix).add(ident"<-").add(ident"_").add(x)
    expectMinLen(x, 3)
    let expr = parseExpression(x)
    var iDef: NimNode
    var iType: NimNode
    if x[1].kind == nnkIdent:
      iDef = x[1]
      iType = newCall(ident"elemType", expr)
    else:
      expectLen(x[1], 1)
      expectMinLen(x[1][0], 2)
      expectKind(x[1][0][0], nnkIdent)
      iDef = x[1][0][0]
      iType = x[1][0][1]
    let lmb = newProc(params = @[ident"auto", newIdentDefs(iDef, iType)], body = result, procType = nnkLambda)
    let p = newNimNode(nnkPragma)
    p.add(ident"closure")
    lmb[4] = p
    if yieldNow:
      yieldNow = false
      result = quote do:
        (`expr`).map(`lmb`)
    else:
      result = quote do:
        (`expr`).flatmap(`lmb`)

macro `[]`*(fc: ForComprehension, comp: untyped): untyped =
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
  forCompImpl(false, comp)

macro act*(comp: untyped): untyped =
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
  let op = newNimNode(nnkInfix)
  op.add(ident"|")
  let res = stmts[stmts.len-1]
  var yieldResult = false
  if res.kind == nnkYieldStmt:
    yieldResult = true
    op.add(res[0].copyNimTree)
  else:
    op.add(res.copyNimTree)
  let par = newNimNode(nnkPar)
  op.add(par)
  for i in 0..<(stmts.len-1):
    par.add(stmts[i].copyNimTree)

  forCompImpl(yieldResult, op)
