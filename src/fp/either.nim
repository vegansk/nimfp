import future, list, option

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
  ## Maps 2 either values via `f`
  a.flatMap((a: A) => b.map((b: B) => f(a,b)))

when compiles(getCurrentException()):
  proc tryE*[A](f: () -> A): EitherE[A] =
    ## Transforms exception to EitherE type
    (try: f().rightE except: getCurrentException().left(A))

  proc flatTryE*[A](f: () -> EitherE[A]): EitherE[A] =
    ## Transforms exception to EitherE type
    (try: f() except: getCurrentException().left(A))
    
when compiles(getCurrentExceptionMsg()):
  proc tryS*[A](f: () -> A): EitherS[A] =
    ## Transforms exception to EitherS type
    (try: f().rightS except: getCurrentExceptionMsg().left(A))
    
  proc flatTryS*[A](f: () -> EitherS[A]): EitherS[A] =
    ## Transforms exception to EitherS type
    (try: f() except: getCurrentExceptionMsg().left(A))
    
proc traverse*[E,A,B](xs: List[A], f: A -> Either[E,B]): Either[E,List[B]] =
  xs.foldRight(Nil[B]().right(E), (x: A, xs: Either[E,List[B]]) => f(x).map2(xs, (y: B, ys: List[B]) => y ^^ ys))

proc sequence*[E,A](xs: List[Either[E,A]]): Either[E,List[A]] =
  xs.traverse((x: Either[E,A]) => x)

proc forEach*[E,A](a: Either[E,A], f: A -> void): void =
  ## Applies `f` to the Either's value if it's right
  if a.isRight:
    f(a.get)

proc cond*[E,A](flag: bool, a: A, e: E): Either[E,A] =
  ## If the condition is satisfied, return a else return e
  if flag: a.right(E) else: e.left(A)

proc condF*[E,A](flag: bool, a: () -> A, e: () -> E): Either[E,A] =
  ## If the condition is satisfied, return a else return e
  if flag: a().right(E) else: e().left(A)

proc asEither*[E,A](o: Option[A], e: E): Either[E,A] = 
  ## Convert Option to Either type
  condF(o.isDefined, () => o.get, () => e)

proc asEitherF*[E,A](o: Option[A], e: () -> E): Either[E,A] = 
  ## Convert Option to Either type
  condF(o.isDefined, () => o.get, e())

template elemType*(v: Either): typedesc =
  ## Part of ``do notation`` contract
  type(v.get)
