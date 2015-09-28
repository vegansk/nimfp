import future

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
  EitherE*[A] = Either[Exception, A]
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
  Right[Exception,A](value)

proc rightS*[A](value: A): EitherS[A] =
  ## Constructs right value
  Right[string,A](value)

proc isLeft*[E,A](e: Either[E,A]): bool =
  ## Checks if `e` contains left value
  e.kind == ekLeft

proc isRight*[E,A](e: Either[E,A]): bool =
  ## Checks if `e` contains right value
  e.kind == ekLeft

proc `$`*[E,A](e: Either[E,A]): string =
  ## Returns string representation of `e`
  if e.isLeft:
    "Left(" & $e.lValue & ")"
  else:
    "Right(" & $e.rValue & ")"

proc `==`*[E,A](x, y: Either[E,A]): bool =
  let r = (x.isLeft, y.isLeft)
  if r == (true, true):
    x.lValue == y.lValue
  elif r == (false, false):
    x.rValue == y.rValue
  else:
    false

proc map*[E,A,B](e: Either[E,A], f: A -> B): Either[E,B] =
  if e.isLeft: e.lValue.left(B) else: f(e.rValue).right(E)

proc flatMap*[E,A,B](e: Either[E,A], f: A -> Either[E,B]): Either[E,B] =
  if e.isLeft: e.lValue.left(B) else: f(e.rValue)
