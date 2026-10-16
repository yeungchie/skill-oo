_assert(ycSubProcess::runJob("test -r /") == t "runJob returns t for a readable command")
_assert(ycSubProcess::runJob("test -w /") == nil "runJob returns nil for a failing command")

_TestRunJobDone = t

; END
