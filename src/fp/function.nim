import future,
       classy

type
  Func0*[R] = () -> R
  Func1*[T1,R] = (T1) -> R
  Func2*[T1,T2,R] = (T1,T2) -> R
  Curried2*[T1,T2,R] = T1 -> (T2 -> R)
  Func3*[T1,T2,T3,R] = (T1,T2,T3) -> R
  Curried3*[T1,T2,T3,R] = T1 -> (T2 -> (T3 -> R))
  Func4*[T1,T2,T3,T4,R] = (T1,T2,T3,T4) -> R
  Curried4*[T1,T2,T3,T4,R] = T1 -> (T2 -> (T3 -> (T4 -> R)))
  Func5*[T1,T2,T3,T4,T5,R] = (T1,T2,T3,T4,T5) -> R
  Func6*[T1,T2,T3,T4,T5,T6,R] = (T1,T2,T3,T4,T5,T6) -> R
  Func7*[T1,T2,T3,T4,T5,T6,T7,R] = (T1,T2,T3,T4,T5,T6,T7) -> R
  Func8*[T1,T2,T3,T4,T5,T6,T7,T8,R] = (T1,T2,T3,T4,T5,T6,T7,T8) -> R

proc memoize*[T](f: Func0[T]): Func0[T] =
  ## Create function's value cache (not thread safe yet)
  var hasValue = false
  var value: T
  result = proc(): T =
    if not hasValue:
      hasValue = true
      value = f()
    return value

# Func2
template curried*[T1,T2,R](f: Func2[T1,T2,R]): Curried2[T1,T2,R] =
  (x1: T1) => ((x2: T2) => f(x1, x2))

template uncurried2*[T1,T2,R](f: Curried2[T1,T2,R]): Func2[T1,T2,R] =
  (x1: T1, x2: T2) => f(x1)(x2)

# Func3
template curried*[T1,T2,T3,R](f: Func3[T1,T2,T3,R]): Curried3[T1,T2,T3,R] =
  (x1: T1) => ((x2: T2) => ((x3: T3) => f(x1, x2, x3)))

template curried1*[T1,T2,T3,R](f: Func3[T1,T2,T3,R]): T1 -> Func2[T2,T3,R] =
  (x1: T1) => ((x2: T2, x3: T3) => f(x1, x2, x3))

template uncurried3*[T1,T2,T3,R](f: Curried3[T1,T2,T3,R]): Func3[T1,T2,T3,R] =
  (x1: T1, x2: T2, x3: T3) => f(x1)(x2)(x3)

# Func4
template curried*[T1,T2,T3,T4,R](f: Func4[T1,T2,T3,T4,R]): Curried4[T1,T2,T3,T4,R] =
  (x1: T1) => ((x2: T2) => ((x3: T3) => ((x4: T4) => f(x1, x2, x3, x4))))

template curried1*[T1,T2,T3,T4,R](f: Func4[T1,T2,T3,T4,R]): T1 -> Func3[T2,T3,T4,R] =
  (x1: T1) => ((x2: T2, x3: T3, x4: T4) => f(x1, x2, x3, x4))

template uncurried4*[T1,T2,T3,T4,R](f: Curried4[T1,T2,T3,T4,R]): Func4[T1,T2,T3,T4,R] =
  (x1: T1, x2: T2, x3: T3, x4: T4) => f(x1)(x2)(x3)(x4)

proc compose*[A,B,C](f: B -> C, g: A -> B): A -> C =
  (x: A) => f(g(x))

proc andThen*[A,B,C](f: A -> B, g: B -> C): A -> C =
  (x: A) => g(f(x))

proc `<<<`*[A,B,C](f: B -> C, g: A -> B): A -> C =
  compose(f, g)

proc `>>>`*[A,B,C](f: A -> B, g: B -> C): A -> C =
  andThen(f, g)

proc flip*[A,B,C](f: Func2[B,A,C]): Func2[A,B,C] =
  (a: A, b: B) => f(b, a)

proc flip*[A,B,C](f: Curried2[B,A,C]): Curried2[A,B,C] =
  (a: A) => ((b: B) => f(b)(a))
