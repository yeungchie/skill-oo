;--------------------------
; Program  : ycLog isolated regression(isolated.il)
; Language : Cadence Skill
;--------------------------

; 只加载 registry、pathlib 与 log，验证 ycDateTime 未加载时的构造器守卫。
; 必须在尚未加载 ycDateTime 的会话中运行；log 套件的 load.il 会在首次加载 log 后自动调用。

let((res path dir)
    res = errset(get_filename(piport) nil)
    path = when(res && car(res) && stringp(car(res)) && car(res) != ""
        car(res)
    )
    unless(path
        error("ycLog isolated: can't determine the current file - load this file with an explicit path")
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
    unless(and(
            findNamespace("ycLog")
            findSymbol("Logger" ?namespace "ycLog")
            fboundp(findSymbol("Logger" ?namespace "ycLog"))
        )
        loadi(strcat(dir "../../libs/log/load.il"))
    )
)

; 加载 log 后 ycDateTime 命名空间只会是空壳；真正加载过则本检查前提不成立。
when(fboundp('ycDateTime:::Current)
    error("ycLog isolated: ycDateTime is already loaded; run this file in a fresh session")
)
let((res msg)
    res = errset(ycLog::Logger("isolated" ?console nil) nil)
    when(errset.errset && 4 <= length(errset.errset)
        msg = car(car(cdr(cdr(cdr(cdr(errset.errset))))))
    )
    unless(!res && msg && index(msg "ycDateTime is not loaded")
        error("ycLog isolated: timestamped logger must report missing ycDateTime")
    )
    res = errset(ycLog::Logger("isolated" ?console nil ?timeFormat nil) nil)
    unless(res
        error("ycLog isolated: timestamp-free logger must construct without ycDateTime")
    )
)
printf("YC LOG ISOLATED PASSED\n")

; END
