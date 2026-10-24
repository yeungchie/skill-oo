_Assert(ycSubProcess::Run("test -r /") == t "Run returns t for a readable command")
_Assert(ycSubProcess::Run("test -w /") == nil "Run returns nil for a failing command")
_Assert(ycSubProcess::Run("test" "-r" "/") == t "Run joins multiple arguments into one command")

_TestRunDone = t

; END
