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
    aj = ycSubProcess::createJob("cat" ?callback _TestCallbackHook ?userData "UD-1")
    aj->start()
    aj->print("a")
    aj->wait(1)
    aj->close()
    aj->await()
    l_events = car(_TestCallbackEvents)
    _assert(l_events != nil "the callback receives lifecycle events")
    _assert(car(l_events) == 'beforeBegin "beforeBegin is the first event")
    _assert(cadr(l_events) == 'afterBegin "afterBegin is the second event")
    _assert(member('stdout l_events) "stdout is fired on child output")
    _assert(member('stderr l_events) == nil "stderr is not fired for a silent command")
    _assert(car(reverse(l_events)) == 'post "post is the last event")
    _assert(_TestCallbackUserData == "UD-1" "the callback observes the job userData")
)

let((aj l_events)
    _TestCallbackEvents = nil
    aj = ycSubProcess::createJob("ls /nonexistent-ycprobe" ?callback _TestCallbackHook)
    aj->await()
    l_events = car(_TestCallbackEvents)
    _assert(member('stderr l_events) "stderr is fired on child error output")
    _assert(aj->stderr->isEmpty() == nil "the stderr stream captured the error output")
    _assert(aj->stdout->isEmpty() == t "the stdout stream stayed empty")
    _assert(member('post l_events) "post is fired for a failing command")
)

_TestCallbackDone = t

; END
