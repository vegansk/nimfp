import macros, strutils, sequtils

type ForComprehension = distinct object

var fc*: ForComprehension

macro `[]`*(fc: ForComprehension, comp: expr): expr =
  expectLen(comp, 3)
  expectKind(comp, nnkInfix)
  expectKind(comp[0], nnkIdent)
  assert($comp[0].ident == "|")

  result = comp[1]

  for i in countdown(comp[2].len-1, 0):
    let x = comp[2][i]
    expectLen(x, 3)
    expectLen(x[1], 1)
    expectMinLen(x[1][0], 2)
    expectKind(x[1][0][0], nnkIdent)
    let cont = x[2]
    let lmb = newProc(params = @[ident"auto", newIdentDefs(x[1][0][0], x[1][0][1])], body = result, procType = nnkLambda)
    result = quote do:
      `cont`.flatMap(`lmb`)

macro act*(comp: untyped): expr =
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
