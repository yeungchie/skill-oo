;--------------------------
; Program  : codec load-order regression
; Language : Cadence Skill
;--------------------------
; 子套件在 let 之外加载：测试执行期间少一层局部作用域，
; 给深层嵌套用例留出调用栈余量。

let((res path dir)
    res = errset(get_filename(piport) nil)
    path = when(res && car(res) && stringp(car(res)) && car(res) != ""
        car(res)
    )
    unless(path
        error("codec load order: can't determine the current file - load this file with an explicit path")
    )
    unless(pcreMatchp("^[~/]|^\.{1,2}/" path)
        path = strcat("./" path)
    )
    dir = simplifyFilename(pcreReplace(pcreCompile("(?<=/)[^/]+/*$") path "" 0) t)
    unless(pcreMatchp("/$" dir)
        dir = strcat(dir "/")
    )
    _OrderTestDir = dir
)

loadi(strcat(_OrderTestDir "../tabulate/load.il"))
loadi(strcat(_OrderTestDir "json/load.il"))
loadi(strcat(_OrderTestDir "csv/load.il"))
loadi(strcat(_OrderTestDir "../tabulate/load.il"))
printf("LOAD ORDER REGRESSION PASSED\n")

; END
