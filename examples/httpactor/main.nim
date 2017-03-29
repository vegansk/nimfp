import boost.http.asynchttpserver,
       asyncdispatch,
       asyncnet

const useActors = true

proc fac(i: int64): int64 =
  if i == 0:
    result = 1'i64
  else:
    result = i * fac(i - 1'i64)

when useActors:
  import ../../src/fp

  # For asynchttpserver we can use only sequental or async strategies here
  let httpActor = newActor[Request](asyncStrategy, dequeQueue) do(req: Request) -> void:
    discard req.respond(Http200, "Factorial of 20 is " & $fac(20'i64))
  let httpActorPtr = httpActor.unsafeAddr

  proc handler(req: Request) {.async.} =
    httpActorPtr ! req
else:
  proc handler(req: Request) {.async.} =
    await req.respond(Http200, "Factorial of 20 is " & $fac(20'i64))

var server = newAsyncHttpServer()

asyncCheck server.serve(Port(5555), handler)

runForever()
