let((aj)
    aj = ycSubProcess::CreateJob("cat")
    aj->start()
    aj->print("a")
    _Assert(aj->close() == t "close returns t")
    _Assert(aj->await() == "a\n" "await drains the remaining output after close")
    _Assert(aj->state() == 'Dead "the job is dead after close ends cat")
)

let((aj)
    aj = ycSubProcess::CreateJob("sleep 5")
    aj->start()
    aj->wait(1)
    _Assert(aj->stop() == t "stop returns t")
    _Assert(aj->state() == 'Stopped "state is 'Stopped after stop")
    _Assert(aj->continue() == t "continue returns t")
    _Assert(aj->state() == 'Active "state is 'Active after continue")
    _Assert(aj->signal('TERM) == t "signal returns t")
    aj->wait(1)
    _Assert(aj->state() == 'Dead "state is 'Dead after SIGTERM")
    _Assert(aj->returncode == 143 "SIGTERM is reported as returncode 143")
    _Assert(aj->kill() == nil "kill on an exited process returns nil")
)

_TestControlDone = t

; END
