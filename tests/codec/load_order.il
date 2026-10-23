;--------------------------
; Program  : codec load-order regression
; Language : Cadence Skill
;--------------------------

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
    loadi(strcat(t_dir "../tabulate/load.il"))
    loadi(strcat(t_dir "json/load.il"))
    loadi(strcat(t_dir "csv/load.il"))
    loadi(strcat(t_dir "../tabulate/load.il"))
    printf("LOAD ORDER REGRESSION PASSED\n")
)

; END
