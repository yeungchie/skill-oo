;--------------------------
; Program  : ycIO tests(load.il)
; Language : Cadence Skill
;--------------------------

let((res path dir)
    res = errset(get_filename(piport) nil)
    path = when(res && car(res) && stringp(car(res)) && car(res) != ""
        car(res)
    )
    unless(path
        error("ycIO: can't determine the current file - load this file with an explicit path")
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
    _TestIODir = dir
)

ycNamespace:::Require("ycIO")
unless(fboundp('ycIO:::Open)
    loadi(strcat(_TestIODir "../../libs/io/load.il"))
)
unless(and(
        findNamespace("ycLang")
        findSymbol("_ycWithHas" ?namespace "ycLang")
        fboundp(findSymbol("_ycWithHas" ?namespace "ycLang"))
    )
    loadi(strcat(_TestIODir "../../libs/lang/load.il"))
)
_TestDir = _TestIODir
unless(fboundp('_TestRun)
    loadi(strcat(_TestDir "../kit.il"))
)
loadi(strcat(_TestDir "test_init.il"))

; END
