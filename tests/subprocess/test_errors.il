let((aj)
    aj = ycSubProcess::createJob("sleep 0")
    _assert(errset(aj->wait() t) == nil "wait raises when the job has not started")
    _assert(errset(aj->kill() t) == nil "kill raises when the job has not started")
    _assert(errset(aj->print("x") t) == nil "print raises when the job has not started")
    _assert(errset(aj->close() t) == nil "close raises when the job has not started")
    _assert(errset(aj->stop() t) == nil "stop raises when the job has not started")
    _assert(errset(aj->continue() t) == nil "continue raises when the job has not started")
    _assert(errset(aj->signal('TERM) t) == nil "signal raises when the job has not started")
)

let((aj)
    aj = ycSubProcess::createJob("sleep 0")
    aj->start()
    _assert(errset(aj->start() t) == nil "start raises when the job is already started")
    aj->wait()
)

let((aj)
    aj = ycSubProcess::createJob("test -w /")
    _assert(errset(aj->await(?check t) t) == nil "await with ?check raises on a non-zero exit")
)

let((aj)
    aj = ycSubProcess::createJob("test -r /")
    _assert(aj->await(?check t) == "" "await with ?check returns stdout on success")
)

_TestErrorsDone = t

; END
