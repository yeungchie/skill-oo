;--------------------------
; Program  : ycLog tests(load.il)
; Language : Cadence Skill
;--------------------------

let((res path dir dtReady)
    res = errset(get_filename(piport) nil)
    path = when(res && car(res) && stringp(car(res)) && car(res) != ""
        car(res)
    )
    unless(path
        error("ycLog: can't determine the current file - load this file with an explicit path")
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
    unless(findNamespace("ycPathLib")
        loadi(strcat(dir "../../libs/pathlib/load.il"))
    )
    dtReady = and(
        findNamespace("ycDateTime")
        findSymbol("Current" ?namespace "ycDateTime")
        fboundp(findSymbol("Current" ?namespace "ycDateTime"))
    )
    when(!dtReady
        loadi(strcat(dir "isolated.il"))
        loadi(strcat(dir "../../libs/datetime/load.il"))
    )
    unless(findNamespace("ycLang")
        loadi(strcat(dir "../../libs/lang/load.il"))
    )
    unless(and(
            findNamespace("ycLog")
            findSymbol("Logger" ?namespace "ycLog")
            fboundp(findSymbol("Logger" ?namespace "ycLog"))
        )
        loadi(strcat(dir "../../libs/log/load.il"))
    )
    _TestDir = dir
    unless(fboundp('_TestRun)
        loadi(strcat(_TestDir "../kit.il"))
    )
    loadi(strcat(_TestDir "test_init.il"))
)

; END
