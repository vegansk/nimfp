import boost.types,
       boost.typeutils,
       threadpool,
       fp.futurem,
       future,
       sharedlist

type Strategy*[A] = proc(a: () -> A): () -> A

proc sequentalStrategy*[A](a: () -> A): () -> A {.procvar.} =
  let r = a()
  result = () => r

proc spawnStrategy*[A](a: proc(): A {.gcsafe.}): () -> A {.procvar.} =
  let r = spawn a()
  result = proc(): auto =
    return ^r

proc asyncStrategy*[A](a: () -> A): () -> A {.procvar.} =
  let f = newFuture[A](a)
  result = proc(): auto =
    f.run.get

#TODO: Implement actor without Channels

type Handler*[A] = proc(v: A) {.gcsafe.}
type HandlerS*[S,A] = proc(s: S, v: A): S {.gcsafe.}
type ErrorHandler* = proc(e: ref Exception): void

let rethrowError*: ErrorHandler = proc(e: ref Exception) =
  raise e

type Actor*[A] = ref object
  strategy: Strategy[Unit]
  handler: Handler[A]
  onError: ErrorHandler
  messages: Channel[A]
  activeReader: bool

proc releaseActor[A](a: Actor[A]) =
  a.messages.close

proc newActor*[A](strategy: Strategy[Unit], handler: Handler[A], onError = rethrowError): Actor[A] =
  new(result, releaseActor[A])
  result.strategy = strategy
  result.handler = handler
  result.onError = onError
  result.messages.open
  result.activeReader = false

proc processQueue[A](a: ptr Actor[A]) =
  while true:
    let (hasMsg, msg) = a[].messages.tryRecv()
    if not hasMsg:
      discard cas(a[].activeReader.addr, true, false)
      break
    try:
      a[].handler(msg)
    except:
      a[].onError(getCurrentException())

proc send*[A](a: Actor[A]|ptr Actor[A], v: A) =
  let ap = when a is ptr: a else: a.unsafeAddr
  ap[].messages.send(v)
  if cas(ap[].activeReader.addr, false, true):
    discard a.strategy(() => (ap.processQueue(); ()))()

proc `!`*[A](a: Actor[A]|ptr Actor[A], v: A) =
  a.send(v)

type ActorS*[S,A] = ref object
  strategy: Strategy[Unit]
  handler: HandlerS[S,A]
  onError: ErrorHandler
  messages: Channel[A]
  state: Channel[S]
  activeReader: bool

proc releaseActorS[S,A](a: ActorS[S,A]) =
  a.state.close
  a.messages.close

proc newActorS*[S,A](strategy: Strategy[Unit], initialState: S, handler: HandlerS[S,A], onError = rethrowError): ActorS[S,A] =
  new(result, releaseActorS[S,A])
  result.strategy = strategy
  result.handler = handler
  result.onError = onError
  result.messages.open
  result.state.open
  result.state.send(initialState)
  result.activeReader = false

proc processQueue[S,A](a: ptr ActorS[S,A]) =
  while true:
    let (hasMsg, msg) = a[].messages.tryRecv()
    if not hasMsg:
      discard cas(a[].activeReader.addr, true, false)
      break
    let (hasState, state) = a[].state.tryRecv()
    assert hasState
    try:
      a[].state.send(a[].handler(state, msg))
    except:
      a[].onError(getCurrentException())
      # Set old state
      a[].state.send(state)

proc send*[S,A](a: ActorS[S,A]|ptr ActorS[S,A], v: A) =
  let ap = when a is ptr: a else: a.unsafeAddr
  ap[].messages.send(v)
  if cas(ap[].activeReader.addr, false, true):
    discard a.strategy(() => (ap.processQueue(); ()))()

proc `!`*[S,A](a: ActorS[S,A]|ptr ActorS[S,A], v: A) =
  a.send(v)
