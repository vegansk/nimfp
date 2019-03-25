import sugar,
       fp,
       strutils,
       unittest,
       boost/types

suite "Concurrent":

  test "Strategy":
    check sequentalStrategy(() => 1)() == 1
    check spawnStrategy(() => 1)() == 1
    check asyncStrategy(() => 1)() == 1

  test "Actor":
    let actor = newActor[string](asyncStrategy, dequeQueue) do(v: string) -> void:
      echo v
    actor ! "Hello, world!"
    actor ! "Hello, world 2!"

  test "Actor with state":
    proc actorF(state, v: string): string =
      result = state
      if v == "end":
        discard #echo state
      else:
        result &= v & "\n"
    let actor = newActorS[string, string](Strategy[Unit](spawnStrategy[Unit]), QueueImpl[string](channelQueue[string]), channelQueue, "", actorF)
    actor ! "Hello, world!"
    actor ! "Hello, world 2!"
    actor ! "end"

  test "Spawn stress test":
    #TODO: Use spawnStrategy when https://github.com/nim-lang/Nim/issues/5626
    #      will be fixed
    let actor = newActor[int](sequentalStrategy, dequeQueue) do(v: int) -> void:
      discard
    for x in 0..10000:
      actor ! 1

