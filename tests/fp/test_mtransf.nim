import unittest,
       future,
       fp.option,
       fp.either,
       fp.forcomp,
       fp.mtransf

suite "Monad transformers":
  test "Basic operations":
    let v = optionTEither(1.some.rightS)
    check: v.getOrElse(2) == 1.rightS
    check: v.map(v => $v).getOrElse("") == "1".rightS
    check: v.flatMap((v: int) => optionTEither(($v).some.rightS)).getOrElse("") == "1".rightS

  test "Do notation support":
    proc getArticle(id: int): EitherS[Option[string]] =
      if id == 0:
        "Not found".left(Option[string])
      else:
        ($id).some.rightS
    let articles = act do:
      a1 <- optionTEither(getArticle(1))
      a2 <- optionTEither(getArticle(2))
      a3 <- optionTEither(getArticle(3))
      optionTEither((a1, a2, a3).some.rightS)
    check: articles.run == ("1", "2", "3").some.rightS
    let badArticles = act do:
      a <- articles
      bad <- optionTEither(getArticle(0))
      (a[0], a[1], a[2], bad).some.rightS.optionTEither
    check: badArticles.run == "Not found".left(Option[(string, string, string, string)])
