import list, future, option

# Initial map realization. Usefull to test the API but not for the production.
# It uses the list of key-value pairs

type
  MapItem*[K,V] = (K,V)
  Map*[K,V] = distinct List[MapItem[K,V]]

proc asMap*[K,V](lst: List[MapItem[K,V]]): Map[K,V] = Map[K,V](lst)
proc asMap*[K,V](xs: varargs[MapItem[K,V]]): Map[K,V] = xs.asList.asMap

proc asList*[K,V](m: Map[K,V]): List[MapItem[K,V]] = List[MapItem[K,V]](m)

proc key*[K,V](item: MapItem[K,V]): K = item[0]
proc value*[K,V](item: MapItem[K,V]): V = item[1]
proc `$`[K,V](item: MapItem[K,V]): string = $item.key & " => " & $item.value

proc `$`*[K,V](m: Map[K,V]): string =
  "Map(" & m.asList.foldLeft("", (s: string, v: (K,V)) => s & (if s == "": "" else: ", ") & $v) & ")"

# future.`->` doesn't support ``MapItem[K,V] -> bool`` declaration
proc find*[K,V](m: Map[K,V], p: proc(i: MapItem[K,V]): bool): Option[MapItem[K,V]] =
  m.asList.find(p)

proc filter*[K,V](m: Map[K,V], p: proc(i: MapItem[K,V]): bool): Map[K,V] =
  m.asList.filter(p).asMap

proc get*[K,V](m: Map[K,V], k: K): Option[V] =
  m.find((i: MapItem[K,V]) => i.key == k).map((v: MapItem[K,V]) => v.value)

proc remove*[K,V](m: Map[K,V], k: K): Map[K,V] =
  m.filter((i: MapItem[K,V]) => i.key != k)

proc `-`*[K,V](m: Map[K,V], k: K): Map[K,V] = m.remove(k)

proc add*[K,V](m: Map[K,V], item: MapItem[K,V]): Map[K,V] =
  (item ^^ m.asList.filter((i: MapItem[K,V]) => i.key != item.key)).asMap

proc `+`*[K,V](m: Map[K,V], item: MapItem[K,V]): Map[K,V] = m.add(item)

proc map*[K,V,K1,V1](m: Map[K,V], f: proc(item: MapItem[K,V]): MapItem[K1,V1]): Map[K1,V1] =
  m.asList.map(f).asMap

proc `==`*[K,V](m1, m2: Map[K,V]): bool =
  m1.asList.forAll((v: MapItem[K,V]) => m1.get(v.key) == m2.get(v.key))
