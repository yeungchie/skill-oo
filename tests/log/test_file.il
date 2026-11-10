_LogReset()

; ---- 追加与截断 ----
let((lg)
    lg = ycLog::Logger("a" ?file _LogTmp("app.log") ?console nil ?timeFormat nil)
    lg->info("one")
    lg->close()
    lg = ycLog::Logger("b" ?file _LogTmp("app.log") ?console nil ?timeFormat nil)
    lg->info("two")
    lg->close()
    _Assert(ycPathLib::Path(_LogTmp("app.log"))->readText()
            == "[INFO] [a] one\n[INFO] [b] two\n"
        "file: default append")
)
let((lg)
    lg = ycLog::Logger("c" ?file _LogTmp("app.log") ?append nil ?console nil ?timeFormat nil)
    lg->info("fresh")
    lg->close()
    _Assert(ycPathLib::Path(_LogTmp("app.log"))->readText()
            == "[INFO] [c] fresh\n"
        "file: append nil truncates")
)

; ---- 落盘控制 ----
let((lg)
    lg = ycLog::Logger("buf" ?file _LogTmp("buf.log") ?console nil ?flush nil ?timeFormat nil)
    lg->info("one")
    _Assert(lg->flush() == t  "file: flush returns t")
    _Assert(ycPathLib::Path(_LogTmp("buf.log"))->readText()
            == "[INFO] [buf] one\n"
        "file: flush makes buffered line visible")
    lg->close()
)
let((lg)
    lg = ycLog::Logger("close" ?file _LogTmp("close.log") ?console nil ?timeFormat nil)
    _Assert(lg->close() == t && lg->close() == t
        "file: close is idempotent")
)

; ---- close 错误路径 ----
let((lg res after)
    lg = ycLog::Logger("full" ?file "/dev/full" ?console nil ?flush nil ?timeFormat nil)
    lg->info("hello")
    res = errset(lg->close() nil)
    _Assert(res == nil && errset.errset  "file: /dev/full close reports an error")
    after = errset(lg->info("again") nil)
    _Assert(after && car(after) == lg  "file: failed close resets the port")
)

; ---- close 之后的控制台与文件 ----
let((lg lines text)
    lg = ycLog::Logger("closed" ?file _LogTmp("closed.log") ?timeFormat nil)
    lg->info("first")
    lg->close()
    text = ycPathLib::Path(_LogTmp("closed.log"))->readText()
    lines = _Capture(_LogTmp("cap.log") lambda(() lg->info("after")))
    _Assert(car(lines) == "[INFO] [closed] after"
        "file: console still works after close")
    _Assert(ycPathLib::Path(_LogTmp("closed.log"))->readText() == text
        "file: file unchanged after close")
)

; ---- 只写文件 ----
let((lg lines)
    lg = ycLog::Logger("quiet" ?file _LogTmp("quiet.log") ?console nil ?timeFormat nil)
    lines = _Capture(_LogTmp("cap2.log") lambda(() lg->info("only-file")))
    lg->close()
    _Assert(lines == nil  "file: console nil writes nothing")
    _Assert(ycPathLib::Path(_LogTmp("quiet.log"))->readText()
            == "[INFO] [quiet] only-file\n"
        "file: console nil still writes file")
)

; ---- 不写文件 ----
let((lg lines)
    lg = ycLog::Logger("nofile" ?file nil ?timeFormat nil)
    lines = _Capture(_LogTmp("cap3.log") lambda(() lg->info("x")))
    _Assert(car(lines) == "[INFO] [nofile] x"
        "file: nil file keeps console only")
    _Assert(index(lsprintf("%A" lg) "file=nil")
        "file: printself shows nil file")
)

_LogCleanup()
_TestChildDone = t

; END
