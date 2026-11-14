;--------------------------
; Program  : ycSubProcess isolated regression(isolated.il)
; Language : Cadence Skill
;--------------------------

; 只加载 registry、pathlib 与 subprocess，验证 ycQueue 未加载时的构造器守卫。
; 必须在尚未加载 ycQueue 的会话中运行；subprocess 套件的 load.il 会在首次加载 subprocess 后自动调用。

let((res path dir)
    res = errset(get_filename(piport) nil)
    path = when(res && car(res) && stringp(car(res)) && car(res) != ""
        car(res)
    )
    unless(path
        error("ycSubProcess isolated: can't determine the current file - load this file with an explicit path")
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
)

; 加载 subprocess 后 ycQueue 命名空间只会是空壳；真正加载过则本检查前提不成立。
when(fboundp('ycQueue:::FIFO)
    error("ycSubProcess isolated: ycQueue is already loaded; run this file in a fresh session")
)
let((res msg)
    res = errset(ycSubProcess::CreateJob("echo hi") nil)
    when(errset.errset && 4 <= length(errset.errset)
        msg = car(car(cdr(cdr(cdr(cdr(errset.errset))))))
    )
    unless(!res && msg && index(msg "ycQueue is not loaded - load it first")
        error("ycSubProcess isolated: constructor must report the missing ycQueue")
    )
)
printf("YC SUBPROCESS ISOLATED PASSED\n")

; END
