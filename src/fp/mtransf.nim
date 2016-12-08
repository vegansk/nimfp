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

  proc getOrElse[A](o: OptionTF[A], v: A): F[A] =
    o.run.map((o: Option[A]) => o.getOrElse(v))

  proc map[A,B](o: OptionTF[A], f: A -> B): OptionTF[B] =
    optionT(o.run.map((o: Option[A]) => o.map(f)))

  proc flatMap[A,B](o: OptionTF[A], f: A -> OptionTF[B]): OptionTF[B] =
    o.run.flatMap(
      (opt: Option[A]) => (if opt.isDefined: opt.get.f.run else: point(F[Option[B]], B.none))
    ).optionT

  template elemType[A](v: OptionTF[A]): typedesc =
    ## Part of ``do notation`` contract
    A

instance OptionTInst, [Option[_], OptionTOption[_]], exporting(_)

instance OptionTInst, E => [Either[E, _], OptionTEither[E,_]], exporting(_)

instance OptionTInst, [List[_], OptionTList[_]], exporting(_)
