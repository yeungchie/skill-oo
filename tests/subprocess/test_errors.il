let((aj)
    aj = ycSubProcess::createJob("sleep 0")
    _assert(errset(aj->wait() nil) == nil "wait raises when the job has not started")
    _assert(errset(aj->kill() nil) == nil "kill raises when the job has not started")
    _assert(errset(aj->print("x") nil) == nil "print raises when the job has not started")
    _assert(errset(aj->close() nil) == nil "close raises when the job has not started")
    _assert(errset(aj->stop() nil) == nil "stop raises when the job has not started")
    _assert(errset(aj->continue() nil) == nil "continue raises when the job has not started")
    _assert(errset(aj->signal('TERM) nil) == nil "signal raises when the job has not started")
)

let((aj)
    aj = ycSubProcess::createJob("sleep 0")
    aj->start()
    _assert(errset(aj->start() nil) == nil "start raises when the job is already started")
    aj->wait()
)

let((aj)
    aj = ycSubProcess::createJob("test -w /")
    _assert(errset(aj->await(?check t) nil) == nil "await with ?check raises on a non-zero exit")
)

let((aj)
    aj = ycSubProcess::createJob("test -r /")
    _assert(aj->await(?check t) == "" "await with ?check returns stdout on success")
)

_TestErrorsDone = t

; END
