_LogReset()

; ---- 正常退出：close 落盘 ----
let((text)
    ycWith(lg ycLog::Logger("with" ?file _LogTmp("with.log")
            ?console nil ?flush nil ?timeFormat nil)
        lg->info("hello")
    )
    text = ycPathLib::Path(_LogTmp("with.log"))->readText()
    _Assert(text == "[INFO] [with] hello\n"
        "with: logger exit closes and flushes")
)

; ---- body 出错：exit 仍执行并落盘 ----
let((text res)
    res = errset(ycWith(lg ycLog::Logger("with" ?file _LogTmp("with2.log")
                ?console nil ?flush nil ?timeFormat nil)
            lg->info("before")
            error("with probe: logger body failure")
        ) nil)
    _Assert(res == nil  "with: logger body error propagates")
    text = ycPathLib::Path(_LogTmp("with2.log"))->readText()
    _Assert(text == "[INFO] [with] before\n"
        "with: logger exit runs on body error")
)

_LogCleanup()
_TestChildDone = t

; END
