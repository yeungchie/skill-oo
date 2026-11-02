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

_Assert(ycSubProcess::Run("true" ?timeout 5) == t
    "Run accepts ?timeout and still returns t")

let((l_res)
    l_res = ycSubProcess::RunWithRead("echo" "hi" ?timeout 5)
    _Assert(car(l_res) == 0 "RunWithRead with ?timeout returns the exit code")
    _Assert(cadr(l_res) == "hi\n" "RunWithRead with ?timeout captures stdout")
)

_Assert(car(ycSubProcess::RunWithRead("sleep" 0 ?timeout 5 ?interval 1)) == 0
    "?interval without a short ?timeout is accepted")

_Assert(errset(ycSubProcess::Run("sleep" 3 ?timeout 1) nil) == nil
    && pcreMatchp("timed out" sprintf(nil "%A" errset.errset))
    "Run raises a timeout error")

_Assert(errset(ycSubProcess::RunWithRead("sleep" 3 ?timeout 1) nil) == nil
    && pcreMatchp("timed out" sprintf(nil "%A" errset.errset))
    "RunWithRead raises a timeout error instead of returning partial output")

_Assert(errset(ycSubProcess::Run("true" ?timeout 0) nil) == nil
    "Run rejects a zero ?timeout")
_Assert(errset(ycSubProcess::Run("true" ?timeout -1) nil) == nil
    "Run rejects a negative ?timeout")
_Assert(errset(ycSubProcess::Run("true" ?timeout 1.5) nil) == nil
    "Run rejects a float ?timeout")
_Assert(errset(ycSubProcess::Run("true" ?timeout "5") nil) == nil
    "Run rejects a string ?timeout")
_Assert(errset(ycSubProcess::RunWithRead("true" ?timeout 0) nil) == nil
    "RunWithRead rejects a zero ?timeout")
_Assert(errset(ycSubProcess::RunWithRead("true" ?interval 0) nil) == nil
    "RunWithRead rejects a zero ?interval")
_Assert(errset(ycSubProcess::Run("true" ?interval "x") nil) == nil
    "Run rejects a string ?interval")

let((l_res)
    l_res = ycSubProcess::RunWithRead("echo" "after" ?timeout 5)
    _Assert(cadr(l_res) == "after\n" "a timed-out job does not block the next command")
)

let((l_res t_start)
    t_start = getCurrentTime()
    l_res = ycSubProcess::RunWithRead("sleep" 0 ?timeout 1)
    _Assert(car(l_res) == 0
        "a command that ends inside ?timeout is not reported as a timeout")
    ; 3 秒是宽松上限：只排除「一直等到 ?timeout 才返回」的实现。
    _Assert(compareTime(getCurrentTime() t_start) < 3
        "a fast command does not wait for ?timeout")
)

; 多参数形式按参数列表拼接：空格与 shell 元字符不再被解释
let((l_res)
    l_res = ycSubProcess::RunWithRead("printf" "<%s>" "a b")
    _Assert(car(l_res) == 0 && cadr(l_res) == "<a b>"
        "argument with a space reaches the command intact")
    l_res = ycSubProcess::RunWithRead("echo" "a;b")
    _Assert(cadr(l_res) == "a;b\n" "semicolon stays inside one argument")
    l_res = ycSubProcess::RunWithRead("echo" "a|b")
    _Assert(cadr(l_res) == "a|b\n" "pipe stays inside one argument")
    l_res = ycSubProcess::RunWithRead("printf" "%s" "it's")
    _Assert(cadr(l_res) == "it's" "an embedded single quote survives quoting")
    l_res = ycSubProcess::RunWithRead("printf" "[%s]" "")
    _Assert(cadr(l_res) == "[]" "an empty argument is kept")
)

let((l_res)
    ; 单参数形式是完整命令串，shell 语法照旧可用
    l_res = ycSubProcess::RunWithRead("sh -c 'printf hi'")
    _Assert(cadr(l_res) == "hi" "single argument stays a full command line")
)

let((l_res t_dir)
    t_dir = "./ycSubProcessTmpSpace"
    when(isDir(t_dir)
        deleteDir(t_dir)
    )
    createDir(t_dir)
    l_res = ycSubProcess::RunWithRead("ls" t_dir)
    _Assert(car(l_res) == 0 && cadr(l_res) == ""
        "a path with a space is passed as one argument")
    deleteDir(t_dir)
)

_TestChildDone = t

; END
