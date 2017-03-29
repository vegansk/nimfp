import boost.types,
       boost.typeutils,
       threadpool,
       ./futurem,
       ./option,
       ./trym,
       future,
       deques,
       locks

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

type Handler*[A] = proc(v: A) {.gcsafe.}
type HandlerS*[S,A] = proc(s: S, v: A): S {.gcsafe.}
type ErrorHandler* = proc(e: ref Exception): void

let rethrowError*: ErrorHandler = proc(e: ref Exception) =
  raise e

# Queue implementation
type Queue*[A] = ref object of RootObj
  init*: proc(q: var Queue[A])
  put*: proc(q: var Queue[A], a: A)
  get*: proc(q: var Queue[A]): Option[A]
  close*: proc(q: var Queue[A])

type QueueImpl*[A] = proc(): Queue[A]

type ChannelQueue[A] = ref object of Queue[A]
  ch: Channel[A]

proc channelQueue*[A](): Queue[A] {.procvar.} =
  result = new(ChannelQueue[A])
  result.init = proc(q: var Queue[A]) =
    let chq = ChannelQueue[A](q)
    chq.ch.open
  result.put = proc(q: var Queue[A], a: A) =
    let chq = ChannelQueue[A](q)
    chq.ch.send(a)
  result.get = proc(q: var Queue[A]): Option[A] =
    let chq = ChannelQueue[A](q)
    let d = chq.ch.tryRecv()
    if d[0]:
      d[1].some
    else:
      A.none
  result.close = proc(q: var Queue[A]) =
    cast[ChannelQueue[A]](q).ch.close

type DequeQueue[A] = ref object of Queue[A]
  q: Deque[A]

proc dequeQueue*[A](): Queue[A] {.procvar.} =
  result = new(DequeQueue[A])
  result.init = proc(q: var Queue[A]) =
    ((DequeQueue[A])q).q = initDeque[A]()
  result.put = proc(q: var Queue[A], a: A) =
    ((DequeQueue[A])q).q.addLast(a)
  result.get = proc(q: var Queue[A]): Option[A] =
    if ((DequeQueue[A])q).q.len > 0:
      ((DequeQueue[A])q).q.popFirst().some
    else:
      A.none
  result.close = proc(q: var Queue[A]) =
    discard

type Actor*[A] = ref object
  strategy: Strategy[Unit]
  handler: Handler[A]
  onError: ErrorHandler
  queue: Queue[A]
  activeReader: bool

proc releaseActor[A](a: Actor[A]) =
  a.queue.close(a.queue)

proc newActor*[A](strategy: Strategy[Unit], queueImpl: QueueImpl[A], handler: Handler[A], onError = rethrowError): Actor[A] =
  new(result, releaseActor[A])
  result.strategy = strategy
  result.handler = handler
  result.onError = onError
  result.queue = queueImpl()
  result.queue.init(result.queue)
  result.activeReader = false

proc processQueue[A](a: ptr Actor[A]) =
  while true:
    let msg = a[].queue.get(a[].queue)
    if msg.isEmpty:
      discard cas(a[].activeReader.addr, true, false)
      break
    try:
      a[].handler(msg.get)
    except:
      a[].onError(getCurrentException())

proc send*[A](a: Actor[A]|ptr Actor[A], v: A) =
  let ap = when a is ptr: a else: a.unsafeAddr
  ap[].queue.put(ap[].queue, v)
  if cas(ap[].activeReader.addr, false, true):
    discard a.strategy(() => (ap.processQueue(); ()))()

proc `!`*[A](a: Actor[A]|ptr Actor[A], v: A) =
  a.send(v)

type ActorS*[S,A] = ref object
  strategy: Strategy[Unit]
  handler: HandlerS[S,A]
  onError: ErrorHandler
  queue: Queue[A]
  state: Queue[S]
  activeReader: bool

proc releaseActorS[S,A](a: ActorS[S,A]) =
  a.state.close(a.state)
  a.queue.close(a.queue)

proc newActorS*[S,A](strategy: Strategy[Unit], queueImpl: QueueImpl[A], stateQueueImpl: QueueImpl[S], initialState: S, handler: HandlerS[S,A], onError = rethrowError): ActorS[S,A] =
  new(result, releaseActorS[S,A])
  result.strategy = strategy
  result.handler = handler
  result.onError = onError
  result.queue = queueImpl()
  result.queue.init(result.queue)
  result.state = stateQueueImpl()
  result.state.init(result.state)
  result.state.put(result.state, initialState)
  result.activeReader = false

proc processQueue[S,A](a: ptr ActorS[S,A]) =
  while true:
    let msg = a[].queue.get(a[].queue)
    if msg.isEmpty:
      discard cas(a[].activeReader.addr, true, false)
      break
    let state = a[].state.get(a[].state)
    assert state.isDefined
    try:
      a[].state.put(a[].state, a[].handler(state.get, msg.get))
    except:
      a[].onError(getCurrentException())
      # Set old state
      a[].state.put(a[].state, state.get)

proc send*[S,A](a: ActorS[S,A]|ptr ActorS[S,A], v: A) =
  let ap = when a is ptr: a else: a.unsafeAddr
  ap[].queue.put(ap[].queue, v)
  if cas(ap[].activeReader.addr, false, true):
    discard a.strategy(() => (ap.processQueue(); ()))()

proc `!`*[S,A](a: ActorS[S,A]|ptr ActorS[S,A], v: A) =
  a.send(v)
