;--------------------------
; Program  : ycSubProcess stream line reading tests(test_stream_lines.il)
; Language : Cadence Skill
;--------------------------

let((st)
    st = makeInstance('ycSubProcess::Stream)
    _Assert(st->peekLine() == nil "peekLine on an empty stream returns nil")
    st->push("123\n456")
    _Assert(st->peekLine() == "123\n" "peekLine returns the first line")
    _Assert(st->peekLine(0) == "123\n" "peekLine(0) returns the first line")
    _Assert(st->peekLine(1) == "456" "peekLine(1) returns the second line")
    _Assert(st->peekLine(-1) == "456" "peekLine(-1) returns the last line")
    _Assert(st->peekLine(-2) == "123\n" "peekLine(-2) returns the first line")
    _Assert(st->peekLine(2) == nil "peekLine past the end returns nil")
    _Assert(st->peekLine(-3) == nil "peekLine before the start returns nil")
    _Assert(st->size() == 1 "peekLine does not split the stored entry")
    _Assert(st->text() == "123\n456" "peekLine does not consume data")
)

let((st)
    st = makeInstance('ycSubProcess::Stream)
    st->push("123\n456")
    _Assert(st->readLine() == "123\n" "readLine returns the first line")
    _Assert(st->size() == 1 "readLine keeps the remainder as one entry")
    _Assert(st->peek() == "456" "the remainder is visible through peek")
    _Assert(st->last() == "456" "the remainder is visible through last")
    _Assert(st->text() == "456" "text includes the remainder")
    _Assert(st->lines() == 1 "lines counts the remainder")
    _Assert(st->readLine() == "456" "readLine returns the final partial line")
    _Assert(st->isEmpty() == t "readLine drains the stream")
    _Assert(st->readLine() == nil "readLine on a drained stream returns nil")
    _Assert(st->text() == "" "text is empty after reading every line")
)

let((st)
    st = makeInstance('ycSubProcess::Stream)
    _Assert(st->read() == nil "read defaults to no waiting")
    _Assert(st->read(?timeout 0) == nil "read with timeout 0 does not wait")
    st->push("x")
    _Assert(st->read(?timeout 0) == "x" "read returns available data with timeout 0")
    _Assert(st->read() == nil "read returns nil on an empty stream")
    _Assert(st->read(?timeout 1) == nil "read without an owner does not wait")
    _AssertErrorMsg(
        lambda(() st->read(?timeout -1))
        "?timeout must be a non-negative number"
        "read rejects a negative timeout"
    )
    _AssertErrorMsg(
        lambda(() st->readLine(?timeout -1))
        "?timeout must be a non-negative number"
        "readLine rejects a negative timeout"
    )
    _AssertErrorMsg(
        lambda(() st->read(?timeout "1"))
        "should be a number"
        "read rejects a string timeout"
    )
    _AssertErrorMsg(
        lambda(() st->readLine(?timeout "1"))
        "should be a number"
        "readLine rejects a string timeout"
    )
)

let((st)
    st = makeInstance('ycSubProcess::Stream)
    st->push("12")
    st->push("3\n45")
    st->push("6\n7")
    _Assert(st->peekLine() == "123\n" "peekLine joins a line across entries")
    _Assert(st->peekLine(1) == "456\n" "peekLine reads the second joined line")
    _Assert(st->peekLine(-1) == "7" "peekLine sees the final partial line")
    _Assert(st->readLine() == "123\n" "readLine joins a line across entries")
    _Assert(st->readLine() == "456\n" "readLine reads the second joined line")
    _Assert(st->readLine() == "7" "readLine returns the final partial line")
    _Assert(st->readLine() == nil "readLine returns nil after the final line")
)

let((st)
    st = makeInstance('ycSubProcess::Stream)
    st->push("a\n")
    st->push("\n")
    st->push("b\n")
    _Assert(st->peekLine() == "a\n" "peekLine reads the first line")
    _Assert(st->peekLine(1) == "\n" "peekLine reads an empty line")
    _Assert(st->peekLine(-1) == "b\n" "peekLine sees the last complete line")
    _Assert(st->peekLine(3) == nil "peekLine ignores the final empty piece")
    _Assert(st->readLine() == "a\n" "readLine reads the first line")
    _Assert(st->readLine() == "\n" "readLine reads an empty line")
    _Assert(st->readLine() == "b\n" "readLine reads the last line")
    _Assert(st->readLine() == nil "readLine returns nil at end of data")
)

let((st)
    st = makeInstance('ycSubProcess::Stream)
    st->push("版图\r\nA")
    _Assert(st->peekLine() == "版图\r\n" "peekLine keeps CRLF and UTF-8 text")
    _Assert(st->peekLine(-1) == "A" "peekLine sees a UTF-8 partial line")
    _Assert(st->readLine() == "版图\r\n" "readLine keeps CRLF and UTF-8 text")
    _Assert(st->readLine() == "A" "readLine returns the UTF-8 partial line")
    _Assert(st->readLine() == nil "readLine returns nil after UTF-8 data")
)

let((st)
    st = makeInstance('ycSubProcess::Stream)
    st->push("ab\ncd")
    _Assert(st->readLine() == "ab\n" "readLine leaves the suffix in front")
    _Assert(st->read() == "cd" "read returns the suffix as one entry")
    _Assert(st->read() == nil "read returns nil after the suffix")
)

let((st)
    st = makeInstance('ycSubProcess::Stream)
    st->push("a\nb")
    st->push("\nc")
    _Assert(st->readLine() == "a\n" "readLine splits a front entry")
    _Assert(st->size() == 2 "size counts the front remainder and the queue")
    _Assert(st->peek() == "b" "peek sees the front remainder")
    _Assert(st->peek(1) == "\nc" "peek sees the queue after the front remainder")
    _Assert(st->peek(-1) == "\nc" "peek(-1) sees the queue tail")
    _Assert(st->last() == "\nc" "last sees the queue tail, not the front remainder")
    _Assert(st->text() == "b\nc" "text joins the front remainder and the queue")
    _Assert(st->peekLine() == "b\n" "peekLine joins the front remainder and the queue")
    _Assert(st->peekLine(-1) == "c" "peekLine sees the queue tail")
    _Assert(st->read() == "b" "read takes the front remainder first")
    _Assert(st->size() == 1 "size drops the consumed front remainder")
    _Assert(st->text(?clear t) == "\nc" "text with clear covers front and queue")
    _Assert(st->isEmpty() == t "text with clear empties front and queue")
)

let((st)
    st = makeInstance('ycSubProcess::Stream)
    st->push("A\n版图")
    _Assert(st->readLine() == "A\n" "readLine splits before UTF-8 text")
    _Assert(st->readLine() == "版图" "readLine returns UTF-8 text after a newline")
    _Assert(st->readLine() == nil "readLine returns nil after the UTF-8 line")
)

let((st)
    st = makeInstance('ycSubProcess::Stream)
    st->push("a\nb")
    _Assert(st->readLine() == "a\n" "readLine creates a front remainder")
    _Assert(st->text(?clear t) == "b" "text with clear includes the front remainder")
    _Assert(st->isEmpty() == t "text with clear removes the front remainder")
)

let((st)
    st = makeInstance('ycSubProcess::Stream)
    st->push("a\nb\nc")
    _Assert(st->readLine() == "a\n" "readLine starts a line sequence")
    _Assert(st->lines() == 2 "lines sees the two remaining lines")
    _Assert(st->readLine() == "b\n" "readLine reads the second line")
    _Assert(st->lines() == 1 "lines sees the final partial line")
    _Assert(st->readLine() == "c" "readLine reads the final partial line")
    _Assert(st->lines() == 0 "lines is zero after the final line")
    _Assert(st->readLine() == nil "readLine returns nil after the final line")
)

let((st)
    st = makeInstance('ycSubProcess::Stream)
    _AssertErrorMsg(
        lambda(() st->peekLine("0"))
        "argument #1 should be an integer"
        "peekLine rejects a string index"
    )
    _AssertErrorMsg(
        lambda(() st->peekLine(0.5))
        "argument #1 should be an integer"
        "peekLine rejects a float index"
    )
)

let((aj)
    aj = ycSubProcess::CreateJob("printf" "partial")->start()->wait()
    _Assert(aj->stdout()->readLine() == "partial" "readLine returns an exited partial line")
    _Assert(aj->stdout()->readLine() == nil "readLine returns nil after exited partial data")
)

let((aj)
    aj = ycSubProcess::CreateJob("cat")->start()
    _Assert(aj->stdout()->read(?timeout 0) == nil "read returns nil before cat output")
    aj->send("abc")
    _Assert(aj->stdout()->read(?timeout 1) == "abc\n" "read waits for cat output")
    aj->kill()
    _Assert(aj->state() == 'Dead "cat job is dead after kill")
)

let((aj)
    aj = ycSubProcess::CreateJob(
        "sh -c 'printf 123; sleep 0.5; printf \"\\n\"'"
    )->start()
    aj->sleep(0.1)
    _Assert(aj->stdout()->readLine() == nil "readLine defaults to no waiting")
    _Assert(aj->stdout()->text() == "123" "readLine leaves partial data in place")
    _Assert(aj->stdout()->readLine(?timeout 1) == "123\n" "readLine waits for a newline")
    _Assert(aj->stdout()->readLine() == nil "readLine returns nil after the waited line")
    aj->wait()
    _Assert(aj->returncode() == 0 "the waited job exits with zero")
)

let((aj)
    aj = ycSubProcess::CreateJob("sleep 1")->start()
    _Assert(aj->stdout()->read(?timeout 0.1) == nil "read times out without data")
    _Assert(aj->stdout()->readLine(?timeout 0.1) == nil "readLine times out without data")
    aj->kill()
    _Assert(aj->state() == 'Dead "the timed-out job is dead after kill")
)

let((aj)
    aj = ycSubProcess::CreateJob("cat")->start()
    aj->stop()
    _Assert(aj->state() == 'Stopped "cat job is stopped")
    _Assert(aj->stdout()->readLine() == nil "readLine does not wait on a stopped job by default")
    _AssertErrorMsg(
        lambda(() aj->stdout()->readLine(?timeout 1))
        "job is stopped"
        "readLine reports a stopped job when waiting"
    )
    _AssertErrorMsg(
        lambda(() aj->stdout()->read(?timeout 1))
        "job is stopped"
        "read reports a stopped job when waiting"
    )
    aj->kill()
    _Assert(aj->state() == 'Dead "the stopped job is dead after kill")
)

let((aj)
    aj = ycSubProcess::CreateJob(
        "sh -c 'printf 123; sleep 1; printf \"\\n\"'"
    )->start()
    aj->sleep(0.1)
    _Assert(aj->stdout()->peekLine() == "123" "peekLine never waits for a newline")
    _Assert(aj->stdout()->peekLine(-1) == "123" "peekLine sees the active partial line")
    _Assert(aj->stdout()->text() == "123" "peekLine leaves active partial data intact")
    aj->kill()
    _Assert(aj->state() == 'Dead "the peeked job is dead after kill")
)

let((aj)
    aj = ycSubProcess::CreateJob(
        "sh -c 'printf 456; sleep 1; printf \"\\n\"'"
    )->start()
    aj->sleep(0.1)
    _Assert(aj->stdout()->readLine(?timeout 0.1) == nil "readLine timeout returns nil")
    _Assert(aj->stdout()->text() == "456" "readLine timeout leaves partial data intact")
    aj->kill()
    _Assert(aj->state() == 'Dead "the timed-out line job is dead after kill")
)

_TestChildDone = t

; END
