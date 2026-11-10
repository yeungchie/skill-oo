;--------------------------
; Program  : ycString tests(load.il)
; Language : Cadence Skill
;--------------------------

let((res path dir)
    res = errset(get_filename(piport) nil)
    path = when(res && car(res) && stringp(car(res)) && car(res) != ""
        car(res)
    )
    unless(path
        error("ycString: can't determine the current file - load this file with an explicit path")
    )
    unless(pcreMatchp("^[~/]|^\\.{1,2}/" path)
        path = strcat("./" path)
    )
    dir = simplifyFilename(pcreReplace(pcreCompile("(?<=/)[^/]+/*$") path "" 0) t)
    unless(pcreMatchp("/$" dir)
        dir = strcat(dir "/")
    )
    unless(and(
            findNamespace("ycString")
            findSymbol("Split" ?namespace "ycString")
            fboundp(findSymbol("Split" ?namespace "ycString"))
        )
        ; libs/string/load.il relies on ycPathLib; when ycPathLib is absent,
        ; enter through libs/load.il so the bootstrap order is respected.
        if(and(
                findNamespace("ycPathLib")
                findSymbol("Path" ?namespace "ycPathLib")
                fboundp(findSymbol("Path" ?namespace "ycPathLib"))
            )
            loadi(simplifyFilename(strcat(dir "../../libs/string/load.il") t))
            loadi(simplifyFilename(strcat(dir "../../libs/load.il") t))
        )
        printf("ycString: re-running tests with previously loaded code; restart CIW if you edited libs/string/src/\n")
    )
    _TestDir = dir
    unless(fboundp('_TestRun)
        loadi(strcat(_TestDir "../kit.il"))
    )
    loadi(strcat(_TestDir "test_init.il"))
)

; END
