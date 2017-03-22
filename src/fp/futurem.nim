import future,
       asyncdispatch,
       fp.trym,
       fp.option,
       classy,
       fp.kleisli,
       boost.types,
       macros,
       fp.function

export asyncdispatch

proc map*[T,U](v: Future[T], f: T -> U): Future[U] =
  var res = newFuture[U]()
  v.callback = () => (block:
    if v.failed:
      res.fail(v.readError)
    else:
      let r = tryM f(v.read)
      if r.isFailure:
        res.fail(r.getError)
      else:
        res.complete(r.get)
  )

  return res

proc flatMap*[T,U](v: Future[T], f: T -> Future[U]): Future[U] =
  var res = newFuture[U]()
  v.callback = () => (block:
    if v.failed:
      res.fail(v.readError)
    else:
      let newF = f(v.read)
      newF.callback = () => (block:
        if newF.failed:
          res.fail(newF.readError)
        else:
          res.complete(newF.read)
      )
  )

  return res

template elemType*(v: Future): typedesc =
  ## Part of ``do notation`` contract
  type(v.read)

proc value*[T](f: Future[T]): Option[Try[T]] =
  if f.finished:
    if f.failed:
      f.readError.failure(T).some
    else:
      f.read.success.some
  else:
    none(Try[T])

proc unit*: Future[Unit] =
  result = newFuture[Unit]()
  result.complete(())

proc newFuture*[T](f: () -> T): Future[T] =
  result = unit().map(_ => f())

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

proc run*[T](f: Future[T]): Try[T] =
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

instance KleisliInst, Future[_], exporting(_)
