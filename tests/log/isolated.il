;--------------------------
; Program  : ycLog isolated regression(isolated.il)
; Language : Cadence Skill
;--------------------------

; 只加载 registry、pathlib 与 log，验证 ycDateTime 未加载时的构造器守卫。
; 必须在尚未加载 ycDateTime 的会话中运行；log 套件的 load.il 会在首次加载 log 后自动调用。

let((t_res t_self t_dir)
    t_res = errset(get_filename(piport) nil)
    t_self = when(t_res && car(t_res) && stringp(car(t_res)) && car(t_res) != ""
        car(t_res)
    )
    unless(t_self
        error("ycLog isolated: can't determine the current file - load this file with an explicit path")
    )
    unless(pcreMatchp("^[~/]|^\\.{1,2}/" t_self)
        t_self = strcat("./" t_self)
    )
    t_dir = simplifyFilename(pcreReplace(pcreCompile("(?<=/)[^/]+/*$") t_self "" 0) t)
    unless(pcreMatchp("/$" t_dir)
        t_dir = strcat(t_dir "/")
    )
    unless(findNamespace("ycNamespace")
        loadi(strcat(t_dir "../../libs/registry.il"))
    )
    unless(findNamespace("ycPathLib")
        loadi(strcat(t_dir "../../libs/pathlib/load.il"))
    )
    when(findNamespace("ycLog") == nil
        loadi(strcat(t_dir "../../libs/log/load.il"))
    )
)

; 加载 log 后 ycDateTime 命名空间只会是空壳；真正加载过则本检查前提不成立。
when(fboundp('ycDateTime:::Current)
    error("ycLog isolated: ycDateTime is already loaded; run this file in a fresh session")
)
let((l_res t_msg)
    l_res = errset(ycLog::Logger("isolated" ?console nil) nil)
    when(errset.errset && 4 <= length(errset.errset)
        t_msg = car(car(cdr(cdr(cdr(cdr(errset.errset))))))
    )
    unless(!l_res && t_msg && index(t_msg "ycDateTime is not loaded")
        error("ycLog isolated: timestamped logger must report missing ycDateTime")
    )
    l_res = errset(ycLog::Logger("isolated" ?console nil ?timeFormat nil) nil)
    unless(l_res
        error("ycLog isolated: timestamp-free logger must construct without ycDateTime")
    )
)
printf("YC LOG ISOLATED PASSED\n")

; END
