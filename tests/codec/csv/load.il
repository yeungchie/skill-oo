;--------------------------
; Program  : ycCsv tests(load.il)
; Language : Cadence Skill
;--------------------------

let((res path dir)
    res = errset(get_filename(piport) nil)
    path = when(res && car(res) && stringp(car(res)) && car(res) != ""
        car(res)
    )
    unless(path
        error("ycCsv: can't determine the current file - load this file with an explicit path")
    )
    unless(pcreMatchp("^[~/]|^\\.{1,2}/" path)
        path = strcat("./" path)
    )
    dir = simplifyFilename(pcreReplace(pcreCompile("(?<=/)[^/]+/*$") path "" 0) t)
    unless(pcreMatchp("/$" dir)
        dir = strcat(dir "/")
    )
    if(findNamespace("ycCsv") == nil || findSymbol("Decode" ?namespace "ycCsv") == nil || !fboundp(findSymbol("Decode" ?namespace "ycCsv"))
        ; libs/codec/csv/load.il relies on ycPathLib; when ycPathLib is absent,
        ; enter through libs/load.il so the bootstrap order is respected.
        if(findNamespace("ycPathLib")
            loadi(simplifyFilename(strcat(dir "../../../libs/codec/csv/load.il") t))
            loadi(simplifyFilename(strcat(dir "../../../libs/load.il") t))
        )
        printf("ycCsv: re-running tests with previously loaded code; restart CIW if you edited libs/codec/csv/src/\n")
    )
    _TestCsvDir = dir
)

let((dir)
    dir = _TestCsvDir
    unless(findNamespace("ycUtf8")
        loadi(simplifyFilename(strcat(dir "../../../libs/utf8/load.il") t))
    )
    unless(findNamespace("ycTextwrap")
        loadi(simplifyFilename(strcat(dir "../../../libs/textwrap/load.il") t))
    )
    unless(fboundp('ycTabulate:::Render)
        loadi(simplifyFilename(strcat(dir "../../../libs/tabulate/load.il") t))
    )
    _TestDir = dir
    unless(fboundp('_TestRun)
        loadi(strcat(_TestDir "../../kit.il"))
    )
    loadi(strcat(_TestDir "test_init.il"))
)

; END
