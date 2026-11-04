_LogReset()

; ---- 阈值与过滤 ----
let((lg lines)
    lg = ycLog::Logger("lvl" ?console nil ?file _LogTmp("a.log") ?timeFormat nil)
    _Assert(lg->level() == 'info  "level: default is info")
    lg->debug("drop")
    lg->info("i")
    lg->warn("w")
    lg->error("e")
    lg->close()
    lines = _ReadLines(_LogTmp("a.log"))
    _Assert(length(lines) == 3  "level: info threshold drops debug")
    _Assert(car(lines) == "[INFO] [lvl] i"  "level: info line")
    _Assert(cadr(lines) == "[WARN] [lvl] w"  "level: warn line")
    _Assert(caddr(lines) == "[ERROR] [lvl] e"  "level: error line")
)

; ---- setLevel 与 debug ----
let((lg lines)
    lg = ycLog::Logger("lvl" ?console nil ?file _LogTmp("b.log") ?timeFormat nil)
    _Assert(lg->setLevel('debug) == lg  "level: setLevel returns self")
    _Assert(lg->level() == 'debug  "level: setLevel updates level")
    lg->debug("d")
    lg->close()
    lines = _ReadLines(_LogTmp("b.log"))
    _Assert(length(lines) == 1 && car(lines) == "[DEBUG] [lvl] d"
        "level: debug emitted after setLevel")
)

; ---- warn 阈值与 log 入口 ----
let((lg lines)
    lg = ycLog::Logger("lvl" ?level 'warn ?console nil ?file _LogTmp("c.log") ?timeFormat nil)
    lg->info("no")
    lg->warn("yes")
    lg->log('error "e")
    lg->close()
    lines = _ReadLines(_LogTmp("c.log"))
    _Assert(length(lines) == 2  "level: warn threshold drops info")
    _Assert(car(lines) == "[WARN] [lvl] yes"  "level: warn kept")
    _Assert(cadr(lines) == "[ERROR] [lvl] e"  "level: log error kept")
)

; ---- log 入口写 info ----
let((lg)
    lg = ycLog::Logger("lvl" ?console nil ?file _LogTmp("d.log") ?timeFormat nil)
    lg->log('info "i")
    lg->close()
    _Assert(car(_ReadLines(_LogTmp("d.log"))) == "[INFO] [lvl] i"
        "level: log info")
)

; ---- error 阈值 ----
let((lg lines)
    lg = ycLog::Logger("lvl" ?console nil ?file _LogTmp("e.log") ?timeFormat nil)
    lg->setLevel('error)
    lg->debug("d")
    lg->info("i")
    lg->warn("w")
    lg->error("e")
    lg->close()
    lines = _ReadLines(_LogTmp("e.log"))
    _Assert(length(lines) == 1  "level: error threshold drops lower levels")
    _Assert(lg->level() == 'error  "level: level reflects error")
    _Assert(car(lines) == "[ERROR] [lvl] e"  "level: error kept")
)

_LogCleanup()
_TestChildDone = t

; END
