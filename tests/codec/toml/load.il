;--------------------------
; Program  : ycToml tests(load.il)
; Language : Cadence Skill
;--------------------------

let((res path dir)
    res = errset(get_filename(piport) nil)
    path = when(res && car(res) && stringp(car(res)) && car(res) != ""
        car(res)
    )
    unless(path
        error("ycToml: can't determine the current file - load this file with an explicit path")
    )
    unless(pcreMatchp("^[~/]|^\\.{1,2}/" path)
        path = strcat("./" path)
    )
    dir = simplifyFilename(pcreReplace(pcreCompile("(?<=/)[^/]+/*$") path "" 0) t)
    unless(pcreMatchp("/$" dir)
        dir = strcat(dir "/")
    )
    if(findNamespace("ycToml") == nil || findSymbol("Decode" ?namespace "ycToml") == nil || !fboundp(findSymbol("Decode" ?namespace "ycToml"))
        ; libs/codec/toml/load.il relies on ycPathLib; when ycPathLib is absent,
        ; enter through libs/load.il so the bootstrap order is respected.
        if(and(
                findNamespace("ycPathLib")
                findSymbol("Path" ?namespace "ycPathLib")
                fboundp(findSymbol("Path" ?namespace "ycPathLib"))
            )
            loadi(simplifyFilename(strcat(dir "../../../libs/codec/toml/load.il") t))
            loadi(simplifyFilename(strcat(dir "../../../libs/load.il") t))
        )
        printf("ycToml: re-running tests with previously loaded code; restart CIW if you edited libs/codec/toml/src/\n")
    )
    _TestDir = dir
    unless(fboundp('_TestRun)
        loadi(strcat(_TestDir "../../kit.il"))
    )
    loadi(strcat(_TestDir "test_init.il"))
)

; END
