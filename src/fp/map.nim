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
  "Map(" & List[MapItem[K,V]](m).foldLeft("", (s: string, v: (K,V)) => s & (if s == "": "" else: ", ") & $v) & ")"

# future.`->` doesn't support ``MapItem[K,V] -> bool`` declaration
proc find*[K,V](m: Map[K,V], p: proc(i: MapItem[K,V]): bool): Option[MapItem[K,V]] =
  m.asList.find(p)

proc get*[K,V](m: Map[K,V], k: K): Option[V] =
  m.find((i: MapItem[K,V]) => i.key == k).map((v: MapItem[K,V]) => v.value)
