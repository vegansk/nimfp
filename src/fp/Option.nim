import future

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

proc `==`*[T](x, y: Option[T]): bool =
  if x.isDefined and y.isDefined:
    x.value == y.value
  elif x.isEmpty and y.isEmpty:
    true
  else:
    false

proc isEmpty*(o: Option): bool =
  ## Checks if option object is empty
  o.kind == okNone

proc isDefined*(o: Option): bool =
  ## Checks if option object contains value
  not o.isEmpty

proc `$`*[T](o: Option[T]): string =
  ## Returns string representation of option object
  if o.isDefined:
    "Some(" & $o.value & ")"
  else:
    "None"
  
proc map*[T,U](o: Option[T], f: T -> U): Option[U] =
  ## Returns option with result of applying f to v's value if it exists
  if o.isDefined:
    f(o.value).some
  else:
    U.none
