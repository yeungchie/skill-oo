_assert(ycSubProcess::createJob("echo -n '123'")->await() == "123" "single-quoted text passes through unchanged")
_assert(ycSubProcess::createJob("echo -n '\"123\"'")->await() == "\"123\"" "double quotes are preserved")
_assert(ycSubProcess::createJob("echo -n '\"1\\23\"'")->await() == "\"1\\23\"" "backslashes are preserved")
_assert(ycSubProcess::createJob("echo -n $HOME")->await() == getShellEnvVar("HOME") "unquoted $HOME expands to the environment value")
_assert(ycSubProcess::createJob("echo -n '$HOME'")->await() == "$HOME" "single-quoted $HOME stays literal")
_assert(ycSubProcess::createJob("echo \"AB\"")->await() == "AB\n" "double quotes are consumed by the shell")
_assert(ycSubProcess::createJob("echo \"$HOME\"")->await() == strcat(getShellEnvVar("HOME") "\n") "double-quoted $HOME expands to the environment value")
_assert(ycSubProcess::createJob("echo a\\b")->await() == "ab\n" "an unquoted backslash escapes the next character")
_assert(ycSubProcess::createJob("echo ab | tr a-z A-Z")->await() == "AB\n" "pipes are interpreted by the shell")

let((aj)
    aj = ycSubProcess::createJob("cat")
    aj->start()
    aj->print("$HOME")
    aj->close()
    _assert(aj->await() == "$HOME\n" "print data reaches the child without shell expansion")
)

_TestRstringDone = t

; END
