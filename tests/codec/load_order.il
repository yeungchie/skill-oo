;--------------------------
; Program  : codec load-order regression
; Language : Cadence Skill
;--------------------------
; 子套件在 let 之外加载：测试执行期间少一层局部作用域，
; 给深层嵌套用例留出调用栈余量。

let((t_res t_self t_dir)
    t_res = errset(get_filename(piport) nil)
    t_self = when(t_res && car(t_res) && stringp(car(t_res)) && car(t_res) != ""
        car(t_res)
    )
    unless(t_self
        error("codec load order: can't determine the current file - load this file with an explicit path")
    )
    unless(pcreMatchp("^[~/]|^\.{1,2}/" t_self)
        t_self = strcat("./" t_self)
    )
    t_dir = simplifyFilename(pcreReplace(pcreCompile("(?<=/)[^/]+/*$") t_self "" 0) t)
    unless(pcreMatchp("/$" t_dir)
        t_dir = strcat(t_dir "/")
    )
    _OrderTestDir = t_dir
)

loadi(strcat(_OrderTestDir "../tabulate/load.il"))
loadi(strcat(_OrderTestDir "json/load.il"))
loadi(strcat(_OrderTestDir "csv/load.il"))
loadi(strcat(_OrderTestDir "../tabulate/load.il"))
printf("LOAD ORDER REGRESSION PASSED\n")

; END
