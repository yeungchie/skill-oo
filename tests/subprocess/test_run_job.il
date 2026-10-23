_assert(ycSubProcess::RunJob("test -r /") == t "runJob returns t for a readable command")
_assert(ycSubProcess::RunJob("test -w /") == nil "runJob returns nil for a failing command")
_assert(ycSubProcess::RunJob("test" "-r" "/") == t "runJob joins multiple arguments into one command")

_TestRunJobDone = t

; END
