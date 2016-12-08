import future,
       ./option,
       ./either

type
  OptionTEither*[E,A] = ref object
    run*: Either[E,Option[A]]

proc optionTEither*[E,A](run: Either[E,Option[A]]): OptionTEither[E,A] =
  OptionTEither[E,A](run: run)

proc getOrElse*[E,A](o: OptionTEither[E,A], v: A): Either[E,A] =
  o.run.map((o: Option[A]) => o.getOrElse(v))

proc map*[E,A,B](o: OptionTEither[E,A], f: A -> B): OptionTEither[E,B] =
  optionTEither(o.run.map((o: Option[A]) => o.map(f)))

proc flatMap*[E,A,B](o: OptionTEither[E,A], f: A -> OptionTEither[E,B]): OptionTEither[E,B] =
  if o.run.isLeft:
    optionTEither(o.run.getLeft.left(Option[B]))
  elif o.run.get.isEmpty:
    optionTEither(B.none.right(E))
  else:
    f(o.run.get.get)

template elemType*(v: OptionTEither): typedesc =
  ## Part of ``do notation`` contract
  type(v.run.get.get)
