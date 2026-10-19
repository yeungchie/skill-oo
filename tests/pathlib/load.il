;--------------------------
; Program  : ycPathLib(load.il)
; Language : Cadence Skill
;--------------------------

let((t_res t_self t_dir)
    t_res = errset(get_filename(piport) nil)
    t_self = when(t_res && car(t_res) && stringp(car(t_res)) && car(t_res) != ""
        car(t_res)
    )
    unless(t_self
        error("ycPathLib: can't determine the current file - load this file with an explicit path")
    )
    unless(pcreMatchp("^[~/]|^\\.{1,2}/" t_self)
        t_self = strcat("./" t_self)
    )
    t_dir = simplifyFilename(pcreReplace(pcreCompile("(?<=/)[^/]+/*$") t_self "" 0) t)
    unless(pcreMatchp("/$" t_dir)
        t_dir = strcat(t_dir "/")
    )
    unless(boundp('_ycModules)
        loadi(strcat(t_dir "../../libs/registry.il"))
    )
    if(findNamespace("ycPathLib") == nil
        loadi(strcat(t_dir "../../libs/pathlib/load.il"))
        printf("ycPathLib: re-running tests with previously loaded code; restart CIW if you edited libs/pathlib/src/\n")
    )
    _TestPathlibDir = t_dir
)

; load reads and evaluates one top-level form at a time; the ycJson shell
; keeps the quoted symbol below readable on a fresh CIW.
ycRequireNamespace("ycJson")
unless(fboundp('ycJson:::decode)
    loadi(strcat(_TestPathlibDir "../../libs/codec/json/load.il"))
)
loadi(strcat(_TestPathlibDir "test_init.il"))

; END
