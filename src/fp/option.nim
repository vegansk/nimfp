import future, strutils

{.experimental.}

type
  OptionKind = enum
    okNone, okSome
  Option*[T] = ref object
    ## Option ADT
    case kind: OptionKind
    of okNone:
      discard
    else:
      value: T

proc Some*[T](value: T): Option[T] =
  ## Constructs option object with value
  Option[T](kind: okSome, value: value)

proc None*[T](): Option[T] =
  ## Constructs empty option object
  Option[T](kind: okNone)

# Some helpers
proc some*[T](value: T): Option[T] = Some(value)
proc none*[T](value: T): Option[T] = None[T]()
proc none*(T: typedesc): Option[T] = None[T]()

proc notNil*[T](o: Option[T]): Option[T] =
  ## Maps nil object to none
  if o.kind == okSome and o.value == nil:
    T.none
  else:
    o

proc notEmpty*(o: Option[string]): Option[string] =
  ## Maps empty string to none
  if o.kind == okSome and o.value.strip == "":
    "".none
  else:
    o

proc `==`*[T](x, y: Option[T]): bool =
  if x.isDefined and y.isDefined:
    x.value == y.value
  elif x.isEmpty and y.isEmpty:
    true
  else:
    false

proc isEmpty*[T](o: Option[T]): bool =
  ## Checks if `o` is empty
  o.kind == okNone

proc isDefined*[T](o: Option[T]): bool =
  ## Checks if `o` contains value
  not o.isEmpty

proc `$`*[T](o: Option[T]): string =
  ## Returns string representation of `o`
  if o.isDefined:
    "Some(" & $o.value & ")"
  else:
    "None"
  
proc map*[T,U](o: Option[T], f: T -> U): Option[U] =
  ## Returns option with result of applying f to the value of `o` if it exists
  if o.isDefined:
    f(o.value).some
  else:
    U.none

proc flatMap*[T,U](o: Option[T], f: T -> Option[U]): Option[U] =
  ## Returns the result of applying `f` if `o` is defined, or none
  if o.isDefined: f(o.value) else: U.none

proc getOrElse*[T](o: Option[T], d: T): T =
  ## Returns option's value if defined, or `d`
  if o.isDefined: o.value else: d

proc getOrElse*[T](o: Option[T], f: void -> T): T =
  ## Returns option's value if defined, or the result of applying `f`
  if o.isDefined: o.value else: f()
  
proc orElse*[T](o: Option[T], d: Option[T]): Option[T] =
  ## Returns `o` if defined, or `d`
  if o.isDefined: o else: d
  
proc orElse*[T](o: Option[T], f: void -> Option[T]): Option[T] =
  ## Returns `o` if defined, or the result of applying `f`
  if o.isDefined: o else: f()
  
proc filter*[T](o: Option[T], p: T -> bool): Option[T] =
  ## Returns `o` if it is defined and the result of applying `p`
  ## to it's value is true
  if o.isDefined and p(o.value): o else: T.none

proc map2*[T,U,V](t: Option[T], u: Option[U], f: (T, U) -> V): Option[V] =
  ## Returns the result of applying f to `t` and `u` value if they are both defined
  if t.isDefined and u.isDefined: f(t.value, u.value).some else: V.none

proc liftO*[T,U](f: T -> U): proc(o: Option[T]): Option[U] =
  ## Turns the function `f` of type `T -> U` into the function
  ## of type `Option[T] -> Option[U]`
  (o: Option[T]) => o.map((x: T) => f(x))
