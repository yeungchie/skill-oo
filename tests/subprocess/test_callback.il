_TestCallbackEvents = nil
_TestCallbackUserData = nil

_TestCallbackHook = lambda((s_event g_job "sg")
    _TestCallbackEvents = tconc(_TestCallbackEvents s_event)
    _TestCallbackUserData = g_job->userData
    nil
)

let((aj l_events)
    _TestCallbackEvents = nil
    _TestCallbackUserData = nil
    aj = ycSubProcess::CreateJob("cat" ?callback _TestCallbackHook ?userData "UD-1")
    aj->start()
    aj->print("a")
    aj->wait(1)
    aj->close()
    aj->await()
    l_events = car(_TestCallbackEvents)
    _Assert(l_events != nil "the callback receives lifecycle events")
    _Assert(car(l_events) == 'beforeBegin "beforeBegin is the first event")
    _Assert(cadr(l_events) == 'afterBegin "afterBegin is the second event")
    _Assert(member('stdout l_events) "stdout is fired on child output")
    _Assert(member('stderr l_events) == nil "stderr is not fired for a silent command")
    _Assert(car(reverse(l_events)) == 'post "post is the last event")
    _Assert(_TestCallbackUserData == "UD-1" "the callback observes the job userData")
)

let((aj l_events)
    _TestCallbackEvents = nil
    aj = ycSubProcess::CreateJob("ls /nonexistent-ycprobe" ?callback _TestCallbackHook)
    aj->await()
    l_events = car(_TestCallbackEvents)
    _Assert(member('stderr l_events) "stderr is fired on child error output")
    _Assert(aj->stderr->isEmpty() == nil "the stderr stream captured the error output")
    _Assert(aj->stdout->isEmpty() == t "the stdout stream stayed empty")
    _Assert(member('post l_events) "post is fired for a failing command")
)

_TestCallbackThrow = lambda((s_event g_job "sg")
    when(s_event == 'stdout
        error("intentional callback failure")
    )
    nil
)

let((aj)
    aj = ycSubProcess::CreateJob("echo hi" ?callback _TestCallbackThrow)
    _Assert(aj->await() == "hi\n" "a failing stdout callback does not interrupt the job")
    _Assert(aj->returncode == 0 "the job finishes with returncode 0 despite the callback error")
)

_TestCallbackDone = t

; END
