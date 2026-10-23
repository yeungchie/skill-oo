let((aj)
    aj = ycSubProcess::CreateJob("cat")
    aj->start()
    aj->print("a")
    _assert(aj->close() == t "close returns t")
    _assert(aj->await() == "a\n" "await drains the remaining output after close")
    _assert(aj->state() == 'Dead "the job is dead after close ends cat")
)

let((aj)
    aj = ycSubProcess::CreateJob("sleep 5")
    aj->start()
    aj->wait(1)
    _assert(aj->stop() == t "stop returns t")
    _assert(aj->state() == 'Stopped "state is 'Stopped after stop")
    _assert(aj->continue() == t "continue returns t")
    _assert(aj->state() == 'Active "state is 'Active after continue")
    _assert(aj->signal('TERM) == t "signal returns t")
    aj->wait(1)
    _assert(aj->state() == 'Dead "state is 'Dead after SIGTERM")
    _assert(aj->returncode == 143 "SIGTERM is reported as returncode 143")
    _assert(aj->kill() == nil "kill on an exited process returns nil")
)

_TestControlDone = t

; END
