import classy,
       future

typeclass KleisliInst, F[_], exported:
  proc `>>=`[A,B](a: F[A], f: A -> F[B]): F[B] =
    a.flatMap(f)

  proc `>=>`[A,B,C](f: A -> F[B], g: B -> F[C]): A -> F[C] =
    (a: A) => f(a).flatMap(g)

