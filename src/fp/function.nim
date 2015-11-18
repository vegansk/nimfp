import future

# Waiting for #3386 to resolve
# type
#   Func0*[R] = () -> R
#   Func1*[T1,R] = (T1) -> R
#   Func2*[T1,T2,R] = (T1,T2) -> R
#   Func3*[T1,T2,T3,R] = (T1,T2,T3) -> R
#   Func4*[T1,T2,T3,T4,R] = (T1,T2,T3,T4) -> R
  
proc memoize*[T](f: () -> T): () -> T =
  ## Create function's value cache (not thread safe yet)
  var hasValue = false
  var value: T
  result = proc(): T =
    if not hasValue:
      hasValue = true
      value = f()
    return value
    
