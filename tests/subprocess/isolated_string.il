;--------------------------
; Program  : ycSubProcess isolated ycString regression(isolated_string.il)
; Language : Cadence Skill
;--------------------------

; 只加载 registry、pathlib、subprocess 与 queue，验证 ycString 未加载时 lines 的守卫。
; 必须在尚未加载 ycString 的会话中运行；subprocess 套件的 load.il 会在加载 ycString 前自动调用。

let((res path dir)
    res = errset(get_filename(piport) nil)
    path = when(res && car(res) && stringp(car(res)) && car(res) != ""
        car(res)
    )
    unless(path
        error("ycSubProcess isolated string: can't determine the current file - load this file with an explicit path")
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
    unless(and(
            findNamespace("ycQueue")
            findSymbol("FIFO" ?namespace "ycQueue")
            fboundp(findSymbol("FIFO" ?namespace "ycQueue"))
        )
        loadi(strcat(dir "../../libs/queue/load.il"))
    )
)

when(fboundp('ycString:::Count)
    error("ycSubProcess isolated string: ycString is already loaded; run this file in a fresh session")
)
let((res msg st)
    st = makeInstance('ycSubProcess::Stream)
    res = errset(st->lines() nil)
    when(errset.errset && 4 <= length(errset.errset)
        msg = car(car(cdr(cdr(cdr(cdr(errset.errset))))))
    )
    unless(!res && msg && index(msg "ycString is not loaded - load it first")
        error("ycSubProcess isolated string: lines must report the missing ycString")
    )
)
printf("YC SUBPROCESS STRING ISOLATED PASSED\n")

; END
