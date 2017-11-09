import ospaths

srcdir = "src"

template dep(name: untyped): untyped =
  exec "nim " & astToStr(name)

proc buildBase(debug: bool, bin: string, src: string) =
  switch("out", (thisDir() & "/" & bin).toExe)
  --nimcache: build
  --threads:on
  if not debug:
    --forceBuild
    --define: release
    --opt: size
  else:
    --define: debug
    --debuginfo
    --debugger: native
    --linedir: on
    --stacktrace: on
    --linetrace: on
    --verbosity: 1

    --NimblePath: src
    --NimblePath: srcdir

  setCommand "c", src

proc test(name: string) =
  if not dirExists "bin":
    mkDir "bin"
  --run
  buildBase true, "bin/test_" & name, "tests/fp/test_" & name

proc example(bin: string, name: string) =
  if not dirExists "bin":
    mkDir "bin"
  --run
  buildBase false, "bin/ex_" & bin, "examples" / name

task test_int, "Run all tests - internal":
  test "all"

task test, "Run all tests":
  dep test_int

task test_either, "Run Either tests":
  test "either"

task test_option, "Run Option tests":
  test "option"

task test_concurrent, "Run concurrent tests":
  test "concurrent"

task test_futurem, "Run futurem tests":
  test "futurem"

task ex_httpactor, "Run httpactor example":
  example "httpactor", "httpactor" / "main"
