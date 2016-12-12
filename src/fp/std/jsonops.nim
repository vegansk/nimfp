import json,
       future,
       ../either,
       ../option

proc mget*(n: JsonNode, key: string|int): EitherS[Option[JsonNode]] =
  ## Returns the child node if it exists, or none.
  ## Returns an error if `key` is int and `n` is not an array, or
  ## if `key` is string and `n` is not an object.
  case n.kind
  of JObject:
    when key is string:
      n.contains(key).optionF(() => n[key]).rightS
    else:
      ("JsonNode.mget: can't use string key with node of type " & $n.kind).left(Option[JsonNode])
  of JArray:
    when key is int:
      (key >= 0 and key < n.len).optionF(() => n[key]).rightS
    else:
      ("JsonNode.mget: can't use int key with node of type " & $n.kind).left(Option[JsonNode])
  else:
    ("JsonNode.mget: can't get the child node from node of type " & $n.kind).left(Option[JsonNode])

proc mget*(n: Option[JsonNode], key: string|int): EitherS[Option[JsonNode]] =
  ## Returns the child node if it exists, or none.
  ## Returns an error if `key` is int and `n` is not an array, or
  ## if `key` is string and `n` is not an object.
  if n.isDefined:
    n.get.mget(key)
  else:
    JsonNode.none.rightS

proc mget*(key: string|int): Option[JsonNode] -> EitherS[Option[JsonNode]] =
  (n: Option[JsonNode]) => n.mget(key)

proc value*[T](t: typedesc[T], n: JsonNode): EitherS[T] =
  ## Returns the value of the node `n` of type `t`
  template checkKind(nKind: JsonNodeKind): untyped =
    if n.kind != nKind:
      raise newException(ValueError, "Can't get Json node's value of kind " & $nKind & ", node's kind is " & $n.kind)
  when t is int:
    tryS do() -> auto:
      JInt.checkKind
      n.getNum.int
  else:
    tryS do() -> auto:
      JString.checkKind
      n.getStr

proc mvalue*[T](t: typedesc[T]): Option[JsonNode] -> EitherS[Option[T]] =
  (n: Option[JsonNode]) => (if n.isDefined: value(T, n.get).map((v: T) => v.some) else: T.none.rightS)

