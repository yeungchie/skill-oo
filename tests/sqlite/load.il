;--------------------------
; Program  : ycSQLite tests(load.il)
; Language : Cadence Skill
;--------------------------

let((res path dir)
    res = errset(get_filename(piport) nil)
    path = when(res && car(res) && stringp(car(res)) && car(res) != ""
        car(res)
    )
    unless(path
        error("ycSQLite: can't determine the current file - load this file with an explicit path")
    )
    unless(pcreMatchp("^[~/]|^\\.{1,2}/" path)
        path = strcat("./" path)
    )
    dir = simplifyFilename(pcreReplace(pcreCompile("(?<=/)[^/]+/*$") path "" 0) t)
    unless(pcreMatchp("/$" dir)
        dir = strcat(dir "/")
    )
    unless(findNamespace("ycSQLite")
        loadi(strcat(dir "../../libs/load.il"))
    )
    _TestDir = dir
    unless(fboundp('_TestRun)
        loadi(strcat(_TestDir "../kit.il"))
    )
    loadi(strcat(_TestDir "test_init.il"))
)

; END
