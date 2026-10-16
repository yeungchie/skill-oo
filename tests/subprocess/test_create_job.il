_assert(ycSubProcess::createJob("echo 123")->await() == "123\n" "await returns child stdout")

let((aj)
    aj = ycSubProcess::createJob("cat")
    errset({
        _assert(aj->state() == 'None "state is 'None before start")
        _assert(aj->start() == aj "start returns the job itself")
        _assert(aj->state() == 'Active "state is 'Active after start")

        _assert(aj->print("123") == aj "print returns the job itself")
        aj->wait(1)
        _assert(aj->stdout->last() == "123\n" "stdout last is the first echoed line")

        _assert(aj->print("456") == aj "print returns the job itself on the second line")
        aj->wait(1)
        _assert(aj->stdout->last() == "456\n" "stdout last is the second echoed line")

        _assert(aj->print("789") == aj "print returns the job itself on the third line")
        aj->wait(1)
        _assert(aj->stdout->last() == "789\n" "stdout last is the third echoed line")

        _assert(aj->stdout->size() == 3 "stdout holds three lines")
        _assert(aj->stdout->isEmpty() == nil "stdout is not empty")

        _assert(aj->stdout->text() == "123\n456\n789\n" "text joins all three lines")
        _assert(aj->stdout->shift() == "123\n" "shift returns the first line")
        _assert(aj->stdout->shift() == "456\n" "shift returns the second line")
        _assert(aj->stdout->shift() == "789\n" "shift returns the third line")
        _assert(aj->stdout->text() == "" "text is empty after shifting every line")

        _assert(aj->stdout->isEmpty() == t "stdout is empty after shifting every line")
    } t)
    when(aj->state() == 'Active
        aj->kill()
    )
    _assert(aj->state() == 'Dead "state is 'Dead after kill")
)

_TestCreateJobDone = t

; END
