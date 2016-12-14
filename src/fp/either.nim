import future,
       boost.types,
       classy,
       ./list,
       ./option,
       ./kleisli

{.experimental.}

type
  EitherKind = enum
    ekLeft, ekRight
  Either*[E,A] = ref object
    ## Either ADT
    case kind: EitherKind
    of ekLeft:
      lValue: E
    else:
      rValue: A
  EitherE*[A] = Either[ref Exception, A]
  EitherS*[A] = Either[string, A]

proc Left*[E,A](value: E): Either[E,A] =
  ## Constructs left value
  Either[E,A](kind: ekLeft, lValue: value)

proc Right*[E,A](value: A): Either[E,A] =
  ## Constructs right value
  Either[E,A](kind: ekRight, rValue: value)

proc left*[E,A](value: E, d: A): Either[E,A] =
  ## Constructs left value
  Left[E,A](value)

proc left*[E](value: E, A: typedesc): Either[E,A] =
  ## Constructs left value
  Left[E,A](value)

proc right*[E,A](value: A, d: E): Either[E,A] =
  ## Constructs right value
  Right[E,A](value)

proc right*[A](value: A, E: typedesc): Either[E,A] =
  ## Constructs right value
  Right[E,A](value)

proc rightE*[A](value: A): EitherE[A] =
  ## Constructs right value
  Right[ref Exception,A](value)

proc rightS*[A](value: A): EitherS[A] =
  ## Constructs right value
  Right[string,A](value)

proc isLeft*[E,A](e: Either[E,A]): bool =
  ## Checks if `e` contains left value
  e.kind == ekLeft

proc isRight*[E,A](e: Either[E,A]): bool =
  ## Checks if `e` contains right value
  e.kind == ekRight

proc `$`(e: ref Exception): string =
  e.msg

proc errorMsg*[A](e: EitherE[A]): string =
  ## Returns error message or empty string
  if e.isLeft:
    e.lValue.msg
  else:
    ""

proc errorMsg*[A](e: EitherS[A]): string =
  ## Returns error message or empty string
  if e.isLeft:
    e.lValue
  else:
    ""

proc `$`*[E,A](e: Either[E,A]): string =
  ## Returns string representation of `e`
  if e.isLeft:
    "Left(" & $e.lValue & ")"
  else:
    "Right(" & $e.rValue & ")"

proc `==`*[E,A](x, y: Either[E,A]): bool =
  ## Compares two values
  let r = (x.isLeft, y.isLeft)
  if r == (true, true):
    x.lValue == y.lValue
  elif r == (false, false):
    x.rValue == y.rValue
  else:
    false

proc map*[E,A,B](e: Either[E,A], f: A -> B): Either[E,B] =
  ## Maps right value of `e` via `f` or returns left value
  if e.isLeft: e.lValue.left(B) else: f(e.rValue).right(E)

proc mapLeft*[E,F,A](e: Either[E,A], f: E -> F): Either[F,A] =
  ## Maps left value of `e` via `f` or returns right value
  if e.isRight: e.rValue.right(F) else: f(e.lValue).left(A)

proc flatMap*[E,A,B](e: Either[E,A], f: A -> Either[E,B]): Either[E,B] =
  ## Returns the result of applying `f` to the right value or returns left value
  if e.isLeft: e.lValue.left(B) else: f(e.rValue)

proc get*[E,A](e: Either[E,A]): A =
  ## Returns either's value if it is right, or fail
  doAssert(e.isRight, "Can't get Either's value")
  e.rValue

proc getLeft*[E,A](e: Either[E,A]): E =
  ## Returns either's value if it is left, or fail
  doAssert(e.isLeft, "Can't get Either's left value")
  e.lValue

proc getOrElse*[E,A](e: Either[E,A], d: A): A =
  ## Return right value or `d`
  if e.isRight: e.rValue else: d

proc getOrElse*[E,A](e: Either[E,A], f: void -> A): A =
  ## Return right value or result of `f`
  if e.isRight: e.rValue else: f()

proc orElse*[E,A](e: Either[E,A], d: Either[E,A]): Either[E,A] =
  ## Returns `e` if it contains right value, or `d`
  if e.isRight: e else: d

proc orElse*[E,A](e: Either[E,A], f: void -> Either[E,A]): Either[E,A] =
  ## Returns `e` if it contains right value, or the result of `f()`
  if e.isRight: e else: f()

proc map2*[E,A,B,C](a: Either[E,A], b: Either[E,B], f: (A, B) -> C): Either[E,C] =
  ## Maps 2 `Either` values via `f`
  a.flatMap((a: A) => b.map((b: B) => f(a,b)))

proc map2F*[A, B, C, E](
  ma: Either[E, A],
  mb: () -> Either[E, B],
  f: (A, B) -> C
): Either[E, C] =
  ## Maps 2 `Either` values via `f`. Lazy in second argument.
  ma.flatMap((a: A) => mb().map((b: B) => f(a, b)))

proc join*[E,A](e: Either[E, Either[E,A]]): Either[E,A] =
  ## Flattens Either's value
  e.flatMap((v: Either[E,A]) => v)

when compiles(getCurrentException()):
  proc tryE*[A](f: () -> A): EitherE[A] =
    ## Transforms exception to EitherE type
    (try: f().rightE except: getCurrentException().left(A))

  proc flatTryE*[A](f: () -> EitherE[A]): EitherE[A] =
    ## Transforms exception to EitherE type
    (try: f() except: getCurrentException().left(A))

  proc tryS*[A](f: () -> A): EitherS[A] =
    ## Transforms exception to EitherS type
    (try: f().rightS except: getCurrentExceptionMsg().left(A))

  proc flatTryS*[A](f: () -> EitherS[A]): EitherS[A] =
    ## Transforms exception to EitherS type
    (try: f() except: getCurrentExceptionMsg().left(A))

  proc run*[E,A](e: Either[E,A]): A =
    ## Returns right value or raises the error contained
    ## in the left part
    if e.isRight:
      result = e.get
    else:
      when E is ref Exception:
        raise e.getLeft
      else:
        raise newException(Exception, $e.getLeft)

proc traverse*[T, E, U](xs: List[T], f: T -> Either[E, U]): Either[E, List[U]] =
  ## Transforms the list of `T` into the list of `U` f via `f` only if
  ## all results of applying `f` are `Right`.
  ## Doesnt execute `f` for elements after the first `Left` is encountered.

  # Implementation with foldRightF breaks semcheck when inferring
  # gcsafe. So we have to keep this basic.
  # Also, since tail calls are not guaranteed, we use a loop instead
  # of recursion.

  var rest = xs
  var acc = Nil[U]()
  while not rest.isEmpty:
    let headRes = f(rest.head)
    if headRes.isLeft:
      return headRes.getLeft.left(List[U])
    acc = Cons(headRes.get, acc)
    rest = rest.tail
  acc.reverse.right(E)

proc sequence*[E,A](xs: List[Either[E,A]]): Either[E,List[A]] =
  xs.traverse((x: Either[E,A]) => x)

proc traverse*[E, A, B](
  opt: Option[A],
  f: A -> Either[E, B]
): Either[E, Option[B]] =
  if opt.isEmpty:
    B.none.rightS
  else:
    f(opt.get).map((b: B) => b.some)

proc forEach*[E,A](a: Either[E,A], f: A -> void): void =
  ## Applies `f` to the Either's value if it's right
  if a.isRight:
    f(a.get)

proc cond*[E,A](flag: bool, a: A, e: E): Either[E,A] =
  ## If the condition is satisfied, returns a else returns e
  if flag: a.right(E) else: e.left(A)

proc condF*[E,A](flag: bool, a: () -> A, e: () -> E): Either[E,A] =
  ## If the condition is satisfied, returns a else returns e
  if flag: a().right(E) else: e().left(A)

proc asEither*[E,A](o: Option[A], e: E): Either[E,A] =
  ## Converts Option to Either type
  condF(o.isDefined, () => o.get, () => e)

proc asEitherF*[E,A](o: Option[A], e: () -> E): Either[E,A] =
  ## Converts Option to Either type 
  condF(o.isDefined, () => o.get, e())

proc asOption*[E,A](e: Either[E,A]): Option[A] =
  ## Converts Either to Option type
  if e.isRight: e.get.some
  else: A.none

proc flip*[E,A](e: Either[E,A]): Either[A,E] =
  ## Flips Either's left and right parts
  if e.isRight: e.get.left(E)
  else: e.getLeft.right(A)

proc whenF*[E](flag: bool, body: () -> Either[E, Unit]): Either[E, Unit] =
  ## Executes `body` if `flag` is true
  if flag: body()
  else: ().right(E)

proc whileM*[E,A](a: A, cond: A -> Either[E, bool], body: A -> Either[E, A]): Either[E,A] =
  ## Executes the body while `cond` returns ``true.right(E)``
  var acc = a
  while true:
    let condRes = cond(acc)
    if condRes.isLeft:
      return condRes.getLeft.left(A)
    elif not condRes.get:
      return acc.right(E)
    result = body(acc)
    if result.isLeft:
      return
    acc = result.get

proc whileM*[E](cond: () -> Either[E, bool], body: () -> Either[E, Unit]): Either[E, Unit] =
  ## Executes the body while `cond` returns ``true.right(E)``
  whileM[E, Unit]((), _ => cond(), _ => body())

proc toUnit*[E,A](e: Either[E,A]): Either[E, Unit] =
  ## Discards the Either's value
  e.flatMap((_:A) => ().right(E))

proc bracket*[E,A,B](
  acquire: () -> Either[E,A],
  release: A -> Either[E, Unit],
  body: A -> Either[E,B]
): Either[E,B] =
  ## Acquires the resource with `acquire`, then executes `body`
  ## and then releases it with `release`.
  acquire().flatMap do (a: A) -> auto:
    let r = body(a)
    release(a).flatMap((_: Unit) => r)

proc catch*[E1,E2,A](
  body: Either[E1,A],
  handler: E1 -> Either[E2,A]
): Either[E2,A] =
  ## Runs `body`. If it fails, execute `handler` with the
  ## value of exception
  if body.isLeft:
    handler(body.getLeft)
  else:
    body.get.right(E2)

proc asEitherS*[E,A](e: Either[E,A]): EitherS[A] =
  ## Converts Either to EitherS
  e.mapLeft((err: E) => $err)

proc asEitherE*[E,A](e: Either[E,A]): EitherE[A] =
  ## Converts Either to EitherE
  e.mapLeft((err: E) => newException(Exception, $err))

proc asList*[E,A](e: Either[E,A]): List[A] =
  ## Converts Either to List
  if e.isLeft:
    Nil[A]()
  else:
    asList(e.get)

template elemType*(v: Either): typedesc =
  ## Part of ``do notation`` contract
  type(v.get)

proc point*[E,A](v: A, e: typedesc[Either[E,A]]): Either[E,A] =
  v.right(E)

instance KleisliInst, E => Either[E,_], exporting(_)
