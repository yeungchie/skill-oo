;--------------------------
; Program  : ycUtf8 tests(load.il)
; Language : Cadence Skill
;--------------------------

let((t_res t_self t_dir)
    t_res = errset(get_filename(piport) nil)
    t_self = when(t_res && car(t_res) && stringp(car(t_res)) && car(t_res) != ""
        car(t_res)
    )
    unless(t_self
        error("ycUtf8: can't determine the current file - load this file with an explicit path")
    )
    unless(pcreMatchp("^[~/]|^\\.{1,2}/" t_self)
        t_self = strcat("./" t_self)
    )
    t_dir = simplifyFilename(pcreReplace(pcreCompile("(?<=/)[^/]+/*$") t_self "" 0) t)
    unless(pcreMatchp("/$" t_dir)
        t_dir = strcat(t_dir "/")
    )
    if(findNamespace("ycUtf8") == nil
        ; libs/utf8/load.il relies on ycPathLib; when ycPathLib is absent,
        ; enter through libs/load.il so the bootstrap order is respected.
        if(findNamespace("ycPathLib")
            loadi(simplifyFilename(strcat(t_dir "../../libs/utf8/load.il") t))
            loadi(simplifyFilename(strcat(t_dir "../../libs/load.il") t))
        )
        printf("ycUtf8: re-running tests with previously loaded code; restart CIW if you edited libs/utf8/src/\n")
    )
    loadi(strcat(t_dir "test_init.il"))
)

; END
