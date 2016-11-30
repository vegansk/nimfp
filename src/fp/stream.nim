import future, option, list, function

type
  StreamNodeKind = enum
    snkEmpty, snkCons
  Stream*[T] = ref object
    ## Lazy stream ADT
    case k: StreamNodeKind
    of snkEmpty:
      discard
    else:
      h: () -> T
      t: () -> Stream[T]

proc Cons*[T](h: () -> T, t: () -> Stream[T]): Stream[T] =
  ## Constructs not empty stream
  Stream[T](k: snkCons, h: h, t: t)

proc Empty*[T](): Stream[T] =
  ## Constructs empty stream
  Stream[T](k: snkEmpty)

proc cons*[T](h: () -> T, t: () -> Stream[T]): Stream[T] =
  ## Constructs not empty stream usime memoized versions of `h` and `t`
  Cons(h.memoize, t.memoize)

proc empty*(T: typedesc): Stream[T] =
  ## Constructs empty stream
  Empty[T]()

proc asStream*[T](xs: varargs[T]): Stream[T] =
  ## Converts arguments list to stream
  let ys = @xs
  proc initStreamImpl(i: int, xs: seq[T]): Stream[T] =
    if i > high(xs):
      T.empty
    else:
      cons(() => xs[i], () => initStreamImpl(i+1, xs))
  initStreamImpl(0, ys)

proc toSeq*[T](xs: Stream[T]): seq[T] =
  ## Converts stream to sequence
  result = @[]
  proc fill(xs: Stream[T], s: var seq[T]) =
    case xs.k
    of snkCons:
      s.add(xs.h())
      xs.t().fill(s)
    else: discard
  xs.fill(result)

proc isEmpty*[T](xs: Stream[T]): bool =
  ## Checks if the stream is empty
  xs.k == snkEmpty
  
proc head*[T](xs: Stream[T]): T =
  ## Returns the head of the stream or throws an exception if empty
  xs.h()

proc headOption*[T](xs: Stream[T]): Option[T] =
  ## Returns the head of the stream or none
  case xs.k
  of snkEmpty: T.none
  else: xs.h().some

proc tail*[T](xs: Stream[T]): Stream[T] =
  ## Return the tail of the stream
  case xs.k
  of snkEmpty: T.empty
  else: xs.t()

proc `==`*[T](xs: Stream[T], ys: Stream[T]): bool =
  ## Checks two streams for equality
  if (xs.k, ys.k) == (snkCons, snkCons):
    xs.h() == ys.h() and xs.t() == ys.t()
  else:
    xs.k == ys.k

proc foldRight*[T,U](xs: Stream[T], z: () -> U, f: (x: T, y: () -> U) -> (() -> U)): U =
  ## Fold right operation for lazy stream
  case xs.k
  of snkEmpty: z()
  else: f(xs.h(), () => xs.t().foldRight(z, f))()

proc foldLeft*[T,U](xs: Stream[T], z: () -> U, f: (y: () -> U, x: T) -> (() -> U)): U =
  ## Fold left operation for lazy stream
  case xs.k
  of snkEmpty: z()
  else: xs.t().foldLeft(f(z, xs.h()), f)

proc toList*[T](xs: Stream[T]): List[T] =
  ## Converts stream to list
  case xs.k
  of snkEmpty: Nil[T]()
  else: xs.h() ^^ xs.t().toList()

proc asList*[T](xs: Stream[T]): List[T] =
  ## Converts stream to list
  xs.toList

proc `$`*[T](xs: Stream[T]): string =
  ## Converts stream to string
  let f = (s: () -> string, x: T) => (() => (
    let ss = s();
    if ss == "": $x else: ss & ", " & $x
  ))
  "Stream(" & xs.foldLeft(() => "", f) & ")"

proc take*[T](xs: Stream[T], n: int): Stream[T] =
  ## Takes `n` first elements of the stream
  if n == 0 or xs.k == snkEmpty:
    T.empty
  else:
    cons(xs.h, () => xs.t().take(n - 1))

proc drop*[T](xs: Stream[T], n: int): Stream[T] =
  ## Drops `n` first elements of the stream
  if n == 0 or xs.k == snkEmpty:
    xs
  else:
    xs.t().drop(n - 1)

proc takeWhile*[T](xs: Stream[T], p: T -> bool): Stream[T] =
  ## Takes elements while `p` is true
  xs.foldRight(() => T.empty(), (x: T, y: () -> Stream[T]) => (() => (if x.p: cons(() => x, y) else: T.empty)))
    
proc dropWhile*[T](xs: Stream[T], p: T -> bool): Stream[T] =
  ## Drops elements while `p` is true
  if xs.k == snkEmpty or not xs.h().p:
    xs
  else:
    xs.t().dropWhile(p)
    
proc forAll*[T](xs: Stream[T], p: T -> bool): bool =
  ## Checks if `p` returns true for all elements in stream
  case xs.k
  of snkEmpty: true
  else: p(xs.h()) and xs.t().forAll(p)

proc map*[T,U](xs: Stream[T], f: T -> U): Stream[U] =
  ## Maps one stream to another
  xs.foldRight(() => U.empty, (x: T, y: () -> Stream[U]) => (() => cons(() => f(x), y)))

proc filter*[T](xs: Stream[T], p: T -> bool): Stream[T] =
  ## Filters stream with predicate `p`
  xs.foldRight(() => T.empty, (x: T, y: () -> Stream[T]) => (() => (if x.p: cons(() => x, y) else: y())))

proc append*[T](xs: Stream[T], x: () -> T): Stream[T] =
  ## Appends `x` to the end of the stream
  xs.foldRight(() => cons(x, () => T.empty), (x: T, y: () -> Stream[T]) => (() => cons(() => x, y)))

proc flatMap*[T,U](xs: Stream[T], f: T -> Stream[U]): Stream[U] =
  ## Flat map operation for the stream
  xs.foldRight(() => U.empty, (x: T, y: () -> Stream[U]) => (() => f(x).foldRight(y, (x: U, y: () -> Stream[U]) => (() => cons(() => x, y)))))

template elemType*(v: Stream): typedesc =
  ## Part of ``do notation`` contract
  type(v.head)
