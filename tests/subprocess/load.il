;--------------------------
; Program  : ycSubProcess(load.il)
; Language : Cadence Skill
;--------------------------

let((res path dir queueReady)
    res = errset(get_filename(piport) nil)
    path = when(res && car(res) && stringp(car(res)) && car(res) != ""
        car(res)
    )
    unless(path
        error("ycSubProcess: can't determine the current file - load this file with an explicit path")
    )
    unless(pcreMatchp("^[~/]|^\\.{1,2}/" path)
        path = strcat("./" path)
    )
    dir = simplifyFilename(pcreReplace(pcreCompile("(?<=/)[^/]+/*$") path "" 0) t)
    unless(pcreMatchp("/$" dir)
        dir = strcat(dir "/")
    )
    unless(findNamespace("ycNamespace")
        loadi(strcat(dir "../../libs/registry.il"))
    )
    unless(and(
            findNamespace("ycPathLib")
            findSymbol("Path" ?namespace "ycPathLib")
            fboundp(findSymbol("Path" ?namespace "ycPathLib"))
        )
        loadi(strcat(dir "../../libs/pathlib/load.il"))
    )
    unless(and(
            findNamespace("ycSubProcess")
            findSymbol("CreateJob" ?namespace "ycSubProcess")
            fboundp(findSymbol("CreateJob" ?namespace "ycSubProcess"))
        )
        loadi(strcat(dir "../../libs/subprocess/load.il"))
    )
    queueReady = and(
        findNamespace("ycQueue")
        findSymbol("FIFO" ?namespace "ycQueue")
        fboundp(findSymbol("FIFO" ?namespace "ycQueue"))
    )
    unless(queueReady
        ; ycQueue 尚未加载：这是唯一能走到守卫错误路径的窗口。
        loadi(strcat(dir "isolated.il"))
        loadi(strcat(dir "../../libs/queue/load.il"))
    )
    _TestDir = dir
    unless(fboundp('_TestRun)
        loadi(strcat(_TestDir "../kit.il"))
    )
    loadi(strcat(_TestDir "test_init.il"))
)

; END
