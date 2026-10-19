;--------------------------
; Program  : skill-oo(libs/load.il)
; Language : Cadence Skill
;--------------------------

; Load the namespace registry first (no dependencies), then bootstrap
; ycPathLib - this loader needs ycPathLib::currentFile below.
let((t_self t_dir)
    t_self = get_filename(piport)
    unless(pcreMatchp("/" t_self)
        t_self = strcat("./" t_self)
    )
    t_dir = pcreReplace(pcreCompile("(?<=/)[^/]+/*$") t_self "" 0)
    load(strcat(t_dir "registry.il"))
    load(strcat(t_dir "pathlib/load.il"))
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
        "string"
        "units"
        "textwrap"
        "tabulate"
    )
    foreach(t_pkg t_pkgs
        t_dir->join(t_pkg "load.il")->load()
    )
)

; END
