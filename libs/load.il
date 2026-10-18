;--------------------------
; Program  : skill-oo(libs/load.il)
; Language : Cadence Skill
;--------------------------

; Bootstrap ycPathLib first - this loader needs ycPathLib::currentFile below.
let((t_self)
    t_self = get_filename(piport)
    unless(pcreMatchp("/" t_self)
        t_self = strcat("./" t_self)
    )
    load(strcat(pcreReplace(pcreCompile("(?<=/)[^/]+/*$") t_self "" 0) "pathlib/load.il"))
)

; pathlib stays outside the loop because the loop itself depends on it;
; every other package goes through the list below (one dir per entry,
; each must contain a load.il).
let((t_dir t_pkgs)
    t_dir = ycPathLib::currentFile()->parent()
    t_pkgs = list(
        "regex"
        "subprocess"
        "codec"
        "utf8"
    )
    foreach(t_pkg t_pkgs
        t_dir->join(t_pkg "load.il")->load()
    )
)

; END
