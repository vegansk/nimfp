import future,
       classy,
       ./option,
       ./either,
       ./list

type
  OptionTOption*[A] = ref object
    run*: Option[Option[A]]
  OptionTEither*[E,A] = ref object
    run*: Either[E,Option[A]]
  OptionTList*[A] = ref object
    run*: List[Option[A]]

typeclass OptionTInst, [F[_], OptionTF[_]], exported:
  proc optionT[A](run: F[Option[A]]): OptionTF[A] =
    OptionTF[A](run: run)

  proc point[A](v: A, t: typedesc[OptionTF[A]]): OptionTF[A] =
    v.point(F[Option[A]]).optionT

  proc getOrElse[A](o: OptionTF[A], v: A): F[A] =
    o.run.map((o: Option[A]) => o.getOrElse(v))

  proc getOrElse[A](o: OptionTF[A], f: () -> A): F[A] =
    o.run.map((o: Option[A]) => o.getOrElse(f))

  proc map[A,B](o: OptionTF[A], f: A -> B): OptionTF[B] =
    optionT(o.run.map((o: Option[A]) => o.map(f)))

  proc flatMap[A,B](o: OptionTF[A], f: A -> OptionTF[B]): OptionTF[B] =
    o.run.flatMap(
      (opt: Option[A]) => (if opt.isDefined: opt.get.f.run else: B.none.point(F[Option[B]]))
    ).optionT

  proc flatMapF[A,B](o: OptionTF[A], f: A -> F[B]): OptionTF[B] =
    o.flatMap((v: A) => f(v).map((v: B) => v.some).optionT)

  template elemType[A](v: OptionTF[A]): typedesc =
    A

instance OptionTInst, [Option[_], OptionTOption[_]], exporting(_)

instance OptionTInst, E => [Either[E, _], OptionTEither[E,_]], exporting(_)

instance OptionTInst, [List[_], OptionTList[_]], exporting(_)
