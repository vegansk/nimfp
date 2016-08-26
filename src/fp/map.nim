import list, future, option, boost.data.rbtree, sequtils

type
  Map*[K,V] = RBTree[K,V]

proc newMap*[K,V]: Map[K,V] = newRBTree[K,V]()

proc asMap*[K,V](lst: List[tuple[k: K, v: V]]): Map[K,V] =
  lst.foldLeft(newMap[K,V](),  (res: Map[K,V], v: tuple[k: K, v: V]) => res.add(v[0], v[1]))
proc asMap*[K,V](xs: varargs[tuple[k: K, v: V]]): Map[K,V] = xs.asList.asMap

proc asList*[K,V](m: Map[K,V]): List[tuple[k: K, v: V]] = toSeq(m.pairs).asList.map((t: (K,V)) => (k: t[0], v: t[1]))

proc key*[K,V](item: tuple[k: K, v: V]): K = item[0]
proc value*[K,V](item: tuple[k: K, v: V]): V = item[1]

proc `$`*[K,V](m: Map[K,V]): string =
  result = "Map("
  var first = true
  for k, v in m.pairs:
    if not first:
      result &= ", "
    else:
      first = not first
    result &= $k & " => " & $v
  result &= ")"

# future.`->` doesn't support ``MapItem[K,V] -> bool`` declaration
proc find*[K,V](m: Map[K,V], p: proc(i: (K,V)): bool): Option[tuple[k: K, v: V]] =
  for k, v in m.pairs:
    if p((k,v)):
      return (k: k, v: v).some
  return none(tuple[k: K, v: V])

proc filter*[K,V](m: Map[K,V], p: proc(i: (K,V)): bool): Map[K,V] =
  result = newMap[K,V]()
  for k, v in m.pairs:
    if p((k, v)):
      result = result.add(k, v)

proc get*[K,V](m: Map[K,V], k: K): Option[V] =
  var v: V
  if m.maybeGet(k, v):
    some(v)
  else:
    none(V)

proc remove*[K,V](m: Map[K,V], k: K): Map[K,V] =
  m.del(k)

template `-`*[K,V](m: Map[K,V], k: K): Map[K,V] = m.remove(k)

proc add*[K,V](m: Map[K,V], item: (K,V)): Map[K,V] =
  m.add(item[0], item[1])

template `+`*[K,V](m: Map[K,V], item: (K,V)): Map[K,V] = m.add(item)

proc map*[K,V,K1,V1](m: Map[K,V], f: proc(item: (K,V)): (K1,V1)): Map[K1,V1] =
  result = newMap[K1,V1]()
  for k, v in m.pairs:
    result = result.add(f((k, v)))

proc `==`*[K,V](m1, m2: Map[K,V]): bool =
  m1.equals(m2)

proc forEach*[K,V](m: Map[K,V], f: proc(item: (K,V)): void): void =
  for k, v in m.pairs:
    f((k, v))

proc forAll*[K,V](m: Map[K,V], p: proc(item: (K,V)): bool): bool =
  result = true
  for k, v in m.pairs:
    if not p((k, v)):
      return false
