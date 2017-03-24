import future,
       fp,
       unittest

suite "Concurrent":

  test "Strategy":
    check sequentalStrategy(() => 1)() == 1
    check spawnStrategy(() => 1)() == 1
    check asyncStrategy(() => 1)() == 1

  test "Actor":
    let actor = newActor[string](spawnStrategy) do(v: string) -> void:
      echo v
    actor ! "Hello, world!"
    actor.unsafeAddr ! "Hello, world 2!"

  test "Actor with state":
    let actor = newActorS[string, string](spawnStrategy, "") do(state, v: string) -> string:
      result = state
      if v == "end":
        echo state
      else:
        result &= v & "\n"
    actor ! "Hello, world!"
    actor.unsafeAddr ! "Hello, world 2!"
    actor.unsafeAddr ! "end"

