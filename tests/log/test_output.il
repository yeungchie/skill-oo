_LogReset()

; ---- 时间戳形态 ----
let((lg lines)
    lg = ycLog::Logger("out" ?console nil ?file _LogTmp("a.log"))
    lg->info("hello")
    lg->close()
    lines = _ReadLines(_LogTmp("a.log"))
    _Assert(pcreMatchp("^\\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\\] \\[INFO\\] \\[out\\] hello$"
            car(lines))
        "output: timestamped line shape")
)

; ---- 关闭时间戳与空名称 ----
let((lg lines)
    lg = ycLog::Logger("out" ?console nil ?file _LogTmp("b.log") ?time nil)
    lg->info("hello")
    lg->close()
    _Assert(car(_ReadLines(_LogTmp("b.log"))) == "[INFO] [out] hello"
        "output: time nil drops timestamp")
)
let((lg)
    lg = ycLog::Logger("" ?console nil ?file _LogTmp("c.log") ?time nil)
    lg->info("hello")
    lg->close()
    _Assert(car(_ReadLines(_LogTmp("c.log"))) == "[INFO] hello"
        "output: empty name drops name segment")
)

; ---- 格式化参数与百分号 ----
let((lg)
    lg = ycLog::Logger("fmt" ?console nil ?file _LogTmp("d.log") ?time nil)
    lg->info("value=%d" 42)
    lg->close()
    _Assert(car(_ReadLines(_LogTmp("d.log"))) == "[INFO] [fmt] value=42"
        "output: format arguments")
)
let((lg)
    lg = ycLog::Logger("pct" ?console nil ?file _LogTmp("e.log") ?time nil)
    lg->info("50% done")
    lg->close()
    _Assert(car(_ReadLines(_LogTmp("e.log"))) == "[INFO] [pct] 50% done"
        "output: percent stays literal without arguments")
)
let((lg)
    lg = ycLog::Logger("pct" ?console nil ?file _LogTmp("f.log") ?time nil)
    lg->info("%d%%" 50)
    lg->close()
    _Assert(car(_ReadLines(_LogTmp("f.log"))) == "[INFO] [pct] 50%"
        "output: percent through format arguments")
)

; ---- 控制台捕获 ----
let((lg lines)
    lg = ycLog::Logger("cap" ?time nil)
    lines = _Capture(_LogTmp("cap.log") lambda(() lg->info("seen")))
    _Assert(length(lines) == 1 && car(lines) == "[INFO] [cap] seen"
        "output: console line")
)
let((lg lines)
    lg = ycLog::Logger("quiet" ?console nil ?time nil)
    lines = _Capture(_LogTmp("quiet.log") lambda(() lg->info("hidden")))
    _Assert(lines == nil  "output: console nil writes nothing to console")
)

; ---- 多行消息 ----
let((lg lines)
    lg = ycLog::Logger("multi" ?console nil ?file _LogTmp("g.log") ?time nil)
    lg->info("a\nb")
    lg->close()
    lines = _ReadLines(_LogTmp("g.log"))
    _Assert(length(lines) == 2 && car(lines) == "[INFO] [multi] a" && cadr(lines) == "b"
        "output: multiline message keeps physical lines")
)

; ---- printself 与方法链 ----
let((lg lines)
    lg = ycLog::Logger("ps" ?file _LogTmp("ps.log") ?level 'warn ?console nil)
    _Assert(pcreMatchp("^<ycLog::Logger name=\"ps\" level=warn file=\"ycLogTmpTest/ps.log\">$"
            lsprintf("%A" lg))
        "output: printself shape")
    _Assert(lg->info("x") == lg  "output: info returns self")
    _Assert(lg->debug("x") == lg  "output: debug returns self")
    _Assert(lg->warn("x") == lg  "output: warn returns self")
    _Assert(lg->error("x") == lg  "output: error returns self")
    _Assert(lg->log('info "x") == lg  "output: log returns self")
    lg->close()
)

_LogCleanup()
_TestChildDone = t

; END
