_assert(ycSubProcess::createJob("echo 123")->await() == "123\n" "await returns child stdout")
_assert(ycSubProcess::createJob("echo" "-n" "AB")->await() == "AB" "multiple arguments are joined with spaces")
_assert(ycSubProcess::createJob("echo" 123)->await() == "123\n" "non-string arguments are converted to text")

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

let((aj)
    aj = ycSubProcess::createJob("cat")
    aj->start()
    aj->print("a")
    aj->wait(1)
    _assert(aj->stdout->shift() == "a\n" "shift drains the first line")
    _assert(aj->stdout->isEmpty() == t "stdout is empty after draining every line")
    _assert(aj->stdout->shift() == nil "shift returns nil on an empty stream")
    _assert(aj->stdout->last() == nil "last returns nil on an empty stream")
    aj->stdout->push("x")
    aj->stdout->push("y")
    _assert(aj->stdout->size() == 2 "push after a full drain appends both entries")
    _assert(aj->stdout->last() == "y" "push after a full drain keeps the true last entry")
    _assert(aj->stdout->text() == "xy" "push after a full drain keeps both entries in order")
    aj->stdout->text(?clear t)
    _assert(aj->stdout->isEmpty() == t "text with ?clear empties the stream")
    aj->stdout->push("z")
    _assert(aj->stdout->text() == "z" "push after text with ?clear works")
    when(aj->state() == 'Active
        aj->kill()
    )
    _assert(aj->state() == 'Dead "state is 'Dead after kill in the drain block")
)

_TestCreateJobDone = t

; END
