;--------------------------
; Program  : ycTextwrap tests(load.il)
; Language : Cadence Skill
;--------------------------

let((res path dir)
    res = errset(get_filename(piport) nil)
    path = when(res && car(res) && stringp(car(res)) && car(res) != ""
        car(res)
    )
    unless(path
        error("ycTextwrap: can't determine the current file - load this file with an explicit path")
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
            findNamespace("ycUtf8")
            findSymbol("Decode" ?namespace "ycUtf8")
            fboundp(findSymbol("Decode" ?namespace "ycUtf8"))
        )
        loadi(strcat(dir "../../libs/utf8/load.il"))
    )
    unless(and(
            findNamespace("ycTextwrap")
            findSymbol("Wrap" ?namespace "ycTextwrap")
            fboundp(findSymbol("Wrap" ?namespace "ycTextwrap"))
        )
        loadi(strcat(dir "../../libs/textwrap/load.il"))
    )
    _TestDir = dir
    unless(fboundp('_TestRun)
        loadi(strcat(_TestDir "../kit.il"))
    )
    loadi(strcat(_TestDir "test_init.il"))
)

; END
