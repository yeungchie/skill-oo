;--------------------------
; Program  : ycIni tests(load.il)
; Language : Cadence Skill
;--------------------------

let((res path dir)
    res = errset(get_filename(piport) nil)
    path = when(res && car(res) && stringp(car(res)) && car(res) != ""
        car(res)
    )
    unless(path
        error("ycIni: can't determine the current file - load this file with an explicit path")
    )
    unless(pcreMatchp("^[~/]|^\\.{1,2}/" path)
        path = strcat("./" path)
    )
    dir = simplifyFilename(pcreReplace(pcreCompile("(?<=/)[^/]+/*$") path "" 0) t)
    unless(pcreMatchp("/$" dir)
        dir = strcat(dir "/")
    )
    if(findNamespace("ycIni") == nil || findSymbol("Decode" ?namespace "ycIni") == nil || !fboundp(findSymbol("Decode" ?namespace "ycIni"))
        ; libs/codec/ini/load.il relies on ycPathLib; when ycPathLib is absent,
        ; enter through libs/load.il so the bootstrap order is respected.
        if(findNamespace("ycPathLib")
            loadi(simplifyFilename(strcat(dir "../../../libs/codec/ini/load.il") t))
            loadi(simplifyFilename(strcat(dir "../../../libs/load.il") t))
        )
        printf("ycIni: re-running tests with previously loaded code; restart CIW if you edited libs/codec/ini/src/\n")
    )
    _TestDir = dir
    unless(fboundp('_TestRun)
        loadi(strcat(_TestDir "../../kit.il"))
    )
    loadi(strcat(_TestDir "test_init.il"))
)

; END
