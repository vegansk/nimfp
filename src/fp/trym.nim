import ./either,
       future,
       macros

type Try*[A] = EitherE[A]
  ## The type representing either exception or successfully
  ## computed value

proc success*[A](v: A): Try[A] =
  ## Create the successfully computed value
  v.rightE

proc failure*[A](e: ref Exception, t: typedesc[A]): Try[A] =
  ## Create the result of failed computation
  e.left(A)

proc failure*[A](msg: string, t: typedesc[A]): Try[A] {.inline.} =
  ## Create the result of failed computation
  try:
    raise newException(Exception, msg)
  except:
    result = getCurrentException().failure(A)

proc fromEither*[E,A](v: Either[E,A]): Try[A] {.inline.}=
  ## Conversion from ``Either[E,A]`` type
  when E is ref Exception:
    v
  elif compiles(v.getLeft().`$`):
    if v.isLeft:
      v.getLeft().`$`.failure(A)
    else:
      v.get.success
  else:
    {.error: "Can't cast Either's left value to string".}

template tryMImpl(body: typed): untyped =
  when compiles((block:
    tryE do() -> auto:
      body
  )):
    tryE do() -> auto:
      body
  else:
    tryE do() -> auto:
      body
      ()

macro tryM*(body: untyped): untyped =
  ## Combination of flatTryS and tryS
  var b = if body.kind == nnkDo: body[^1] else: body
  result = quote do:
    tryMImpl((block:
      `b`
    ))

proc isSuccess*[A](v: Try[A]): bool =
  ## Returns true if `v` contains value
  v.isRight

proc isFailure*[A](v: Try[A]): bool =
  ## Returns true if `v` contains exception
  v.isLeft

proc getError*[A](v: Try[A]): ref Exception =
  ## Returns the exception object
  v.getLeft

proc getErrorMessage*[A](v: Try[A]): string =
  ## Returns the exception message
  v.getError.msg

proc getErrorStack*[A](v: Try[A]): string =
  ## Returns the exception stack trace
  v.getError.getStackTrace

proc recover*[A](v: Try[A], f: ref Exception -> A): Try[A] =
  ## Returns the result of calling `f` if `v` contains the exception.
  ## Otherwise returns `v`
  if v.isFailure:
    f(v.getError).success
  else:
    v

proc recoverWith*[A](v: Try[A], f: ref Exception -> Try[A]): Try[A] =
  ## Returns the result of calling `f` if `v` contains the exception.
  ## Otherwise returns `v`
  if v.isFailure:
    f(v.getError)
  else:
    v
