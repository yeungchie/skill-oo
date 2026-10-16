_assert(ycSubProcess::createJob("echo -n '123'")->await() == "123" "single-quoted text passes through unchanged")
_assert(ycSubProcess::createJob("echo -n '\"123\"'")->await() == "\"123\"" "double quotes are preserved")
_assert(ycSubProcess::createJob("echo -n '\"1\\23\"'")->await() == "\"1\\23\"" "backslashes are preserved")
_assert(ycSubProcess::createJob("echo -n $HOME")->await() == getShellEnvVar("HOME") "unquoted $HOME expands to the environment value")
_assert(ycSubProcess::createJob("echo -n '$HOME'")->await() == "$HOME" "single-quoted $HOME stays literal")

_TestRstringDone = t

; END
