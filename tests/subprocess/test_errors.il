let((aj)
    aj = ycSubProcess::CreateJob("sleep 0")
    _Assert(errset(aj->wait() nil) == nil "wait raises when the job has not started")
    _Assert(errset(aj->kill() nil) == nil "kill raises when the job has not started")
    _Assert(errset(aj->print("x") nil) == nil "print raises when the job has not started")
    _Assert(errset(aj->close() nil) == nil "close raises when the job has not started")
    _Assert(errset(aj->stop() nil) == nil "stop raises when the job has not started")
    _Assert(errset(aj->continue() nil) == nil "continue raises when the job has not started")
    _Assert(errset(aj->signal('TERM) nil) == nil "signal raises when the job has not started")
)

let((aj)
    aj = ycSubProcess::CreateJob("sleep 0")
    aj->start()
    _Assert(errset(aj->start() nil) == nil "start raises when the job is already started")
    aj->wait()
)

let((aj)
    aj = ycSubProcess::CreateJob("test -w /")
    _Assert(errset(aj->await(?check t) nil) == nil "await with ?check raises on a non-zero exit")
)

let((aj)
    aj = ycSubProcess::CreateJob("test -r /")
    _Assert(aj->await(?check t) == "" "await with ?check returns stdout on success")
)

let((aj)
    aj = ycSubProcess::CreateJob("sleep 5")
    aj->start()->wait(1)
    aj->stop()
    _Assert(errset(aj->await() nil) == nil "await raises while the job is stopped")
    aj->kill()
    _Assert(aj->state() == 'Dead "the stopped job is cleared by kill")
)

let((aj)
    aj = ycSubProcess::CreateJob("echo hi")
    aj->await()
    _Assert(errset(aj->print("x") nil) == nil "print raises when the job has exited")
)

_TestErrorsDone = t

; END
