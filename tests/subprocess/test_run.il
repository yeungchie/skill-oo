_Assert(ycSubProcess::Run("test -r /") == t "Run returns t for a readable command")
_Assert(ycSubProcess::Run("test -w /") == nil "Run returns nil for a failing command")
_Assert(ycSubProcess::Run("test" "-r" "/") == t "Run joins multiple arguments into one command")

let((l_res)
    l_res = ycSubProcess::RunWithRead("echo hello")
    _Assert(length(l_res) == 3 "RunWithRead returns code, stdout and stderr")
    _Assert(car(l_res) == 0 "RunWithRead returns the exit code")
    _Assert(cadr(l_res) == "hello\n" "RunWithRead captures stdout")
    _Assert(caddr(l_res) == "" "RunWithRead returns empty stderr when there is no error output")
)

let((l_res)
    l_res = ycSubProcess::RunWithRead("sh -c 'printf out; printf err >&2; exit 7'")
    _Assert(car(l_res) == 7 "RunWithRead keeps a non-zero exit code")
    _Assert(cadr(l_res) == "out" "RunWithRead keeps stdout separate from stderr")
    _Assert(caddr(l_res) == "err" "RunWithRead captures stderr")
)

let((l_res)
    l_res = ycSubProcess::RunWithRead("true")
    _Assert(car(l_res) == 0 "RunWithRead handles a command without output")
    _Assert(cadr(l_res) == "" "RunWithRead returns empty stdout for a silent command")
    _Assert(caddr(l_res) == "" "RunWithRead returns empty stderr for a silent command")
)

let((l_res)
    l_res = ycSubProcess::RunWithRead("echo" 123)
    _Assert(cadr(l_res) == "123\n" "RunWithRead converts non-string arguments to text")
)

_Assert(errset(ycSubProcess::RunWithRead() nil) == nil "RunWithRead requires a command")

_TestRunDone = t

; END
