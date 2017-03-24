import future,
       asyncdispatch,
       fp.trym,
       fp.option,
       classy,
       fp.kleisli,
       boost.types,
       macros,
       fp.function,
       boost.typeclasses

export asyncdispatch

proc value*(f: Future[void]): Option[Try[Unit]] =
  if f.finished:
    if f.failed:
      f.readError.failure(Unit).some
    else:
      ().success.some
  else:
    none(Try[Unit])

proc value*[T: NonVoid](f: Future[T]): Option[Try[T]] =
  if f.finished:
    if f.failed:
      f.readError.failure(T).some
    else:
      f.read.success.some
  else:
    none(Try[T])

proc map*[T: NonVoid,U](v: Future[T], f: T -> U): Future[U] =
  var res = newFuture[U]()
  v.callback = () => (block:
    let vv = v.value.get
    if vv.isFailure:
      res.fail(vv.getError)
    else:
      let fv = tryM f(vv.get)
      if fv.isFailure:
        res.fail(fv.getError)
      else:
        res.complete(fv.get)
  )
  return res

proc map*[U](v: Future[void], f: Unit -> U): Future[U] =
  var res = newFuture[U]()
  v.callback = () => (block:
    if v.failed:
      res.fail(v.readError)
    else:
      let fv = tryM f(())
      if fv.isFailure:
        res.fail(fv.getError)
      else:
        res.complete(fv.get)
  )
  return res

proc flatMap*[U](v: Future[void], f: Unit -> Future[U]): Future[U] =
  var res = newFuture[U]()
  v.callback = () => (block:
    if v.failed:
      res.fail(v.readError)
    else:
      let fv = tryM f(())
      if fv.isFailure:
        res.fail(fv.getError)
      else:
        let fvv = fv.get
        fvv.callback = () => (block:
          if fvv.failed:
            res.fail(fvv.readError)
          else:
            res.complete(fvv.value.get.get)
        )
  )
  return res

proc flatMap*[T: NonVoid,U](v: Future[T], f: T -> Future[U]): Future[U] =
  var res = newFuture[U]()
  v.callback = () => (block:
    if v.failed:
      res.fail(v.readError)
    else:
      let newF = tryM(f(v.value.get.get))
      if newF.isFailure:
        res.fail(newF.getError)
      else:
        newF.get.callback = () => (block:
          let fv = newF.get.value.get
          if newF.isFailure:
            res.fail(fv.getError)
          else:
            if fv.isFailure:
              res.fail(fv.getError)
            else:
              res.complete(fv.get)
        )
  )
  return res

template elemType*(v: Future): typedesc =
  ## Part of ``do notation`` contract
  type(v.value.get.get)

proc unit*[T](v: T): Future[T] =
  result = newFuture[T]()
  when T is void:
    result.complete()
  else:
    result.complete(v)

proc newFuture*[T: NonVoid](f: () -> T): Future[T] =
  result = unit(()).map(_ => f())

template futureImpl(body: typed): untyped =
  newFuture do() -> auto:
    body

macro future*(body: untyped): untyped =
  ## Creates new future from `body`.
  var b = if body.kind == nnkDo: body[^1] else: body
  result = quote do:
    futureImpl((block:
      `b`
    ))

proc run*(f: Future[void]): Try[Unit] =
  while not f.finished:
    asyncdispatch.poll(10)
  f.value.get

proc run*[T: NonVoid](f: Future[T]): Try[T] =
  while not f.finished:
    asyncdispatch.poll(10)
  f.value.get

proc join*[T](f: Future[Future[T]]): Future[T] =
  f.flatMap(id)

proc flattenF*[T](f: Future[Try[T]]): Future[T] =
  f.flatMap do(v: Try[T]) -> auto:
    var res = newFuture[T]()
    if v.isFailure:
      res.fail(v.getError)
    else:
      res.complete(v.get)
    return res

proc onComplete*[T](v: Future[T], f: Try[T] -> void) =
  v.callback = () => (block:
    f(v.value.get)
  )

proc timeout*[T](v: Future[T], timeout: int): Future[Option[T]] =
  let tm = v.withTimeout(timeout)
  let res = newFuture[Option[T]]()
  tm.callback = () => (block:
    if tm.failed:
      res.fail(tm.readError)
    else:
      res.complete(if tm.read: v.read.some else: T.none)
  )
  return res

instance KleisliInst, Future[_], exporting(_)
