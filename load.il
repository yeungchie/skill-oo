;--------------------------
; Program  : skill-oo
; Language : Cadence Skill
;--------------------------

; Resolve this file's own directory, then forward to libs/load.il which
; bootstraps ycPathLib and loads every module under libs/.
let((t_self)
    t_self = get_filename(piport)
    unless(pcreMatchp("/" t_self)
        t_self = strcat("./" t_self)
    )
    load(strcat(pcreReplace(pcreCompile("(?<=/)[^/]+/*$") t_self "" 0) "libs/load.il"))
)

; END
