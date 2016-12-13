import unittest,
       future,
       fp.option,
       fp.either,
       fp.list,
       fp.forcomp,
       fp.mtransf

suite "Monad transformers":
  test "OptionTOption":
    let v = optionT(1.some.some)
    check: v.getOrElse(2) == 1.some
    check: v.map(v => $v).getOrElse("") == "1".some
    check: v.flatMapF((v: int) => ($v).some).getOrElse("") == "1".some
    check: v.flatMap((v: int) => optionT(($v).some.some)).getOrElse("") == "1".some

    proc getArticle(id: int): Option[Option[string]] =
      if id == 0:
        none(Option[string])
      else:
        ($id).some.some
    let articles = act do:
      a1 <- optionT(getArticle(1))
      a2 <- optionT(getArticle(2))
      a3 <- optionT(getArticle(3))
      optionT((a1, a2, a3).some.some)
    check: articles.run == ("1", "2", "3").some.some
    let badArticles = act do:
      a <- articles
      bad <- optionT(getArticle(0))
      (a[0], a[1], a[2], bad).some.some.optionT
    check: badArticles.run == none(Option[(string, string, string, string)])

  test "OptionTEither":
    let v = optionT(1.some.rightS)
    check: v.getOrElse(2) == 1.rightS
    check: v.map(v => $v).getOrElse("") == "1".rightS
    check: v.flatMapF((v: int) => ($v).rightS).getOrElse("") == "1".rightS
    check: v.flatMap((v: int) => optionT(($v).some.rightS)).getOrElse("") == "1".rightS

    proc getArticle(id: int): EitherS[Option[string]] =
      if id == 0:
        "Not found".left(Option[string])
      else:
        ($id).some.rightS
    let articles = act do:
      a1 <- optionT(getArticle(1))
      a2 <- optionT(getArticle(2))
      a3 <- optionT(getArticle(3))
      optionT((a1, a2, a3).some.rightS)
    check: articles.run == ("1", "2", "3").some.rightS
    let badArticles = act do:
      a <- articles
      bad <- optionT(getArticle(0))
      (a[0], a[1], a[2], bad).some.rightS.optionT
    check: badArticles.run == "Not found".left(Option[(string, string, string, string)])

  test "OptionTList":
    let v = optionT([1.some].asList)
    check: v.getOrElse(2) == [1].asList
    check: v.map(v => $v).getOrElse("") == ["1"].asList
    check: v.flatMapF((v: int) => [$v].asList).getOrElse("") == ["1"].asList
    check: v.flatMap((v: int) => optionT([($v).some].asList)).getOrElse("") == ["1"].asList

    proc getArticle(id: int): List[Option[string]] =
      if id == 0:
        Nil[Option[string]]()
      else:
        ($id).some.point(List)
    let articles = act do:
      a1 <- optionT(getArticle(1))
      a2 <- optionT(getArticle(2))
      a3 <- optionT(getArticle(3))
      optionT([(a1, a2, a3).some].asList)
    check: articles.run == [("1", "2", "3").some].asList
    let badArticles = act do:
      a <- articles
      bad <- optionT(getArticle(0))
      [a[0], a[1], a[2], bad].asList.some.asList.optionT
    check: badArticles.run == Nil[Option[List[string]]]()

  test "Misc functions":
    check: string.none.some.optionT.getOrElse("1") == "1".some
    check: string.none.some.optionT.getOrElse(() => "1") == "1".some

    check: string.none.rightS.optionT.getOrElseF(() => "Error".left(string)) == "Error".left(string)
