;--------------------------
; Program  : codec(load.il)
; Language : Cadence Skill
;--------------------------

; libs/load.il bootstraps ycPathLib before this file runs, so the loader
; only needs currentFile() and Path::load to reach every format below.
let((t_dir)
    t_dir = ycPathLib::currentFile()->parent()
    foreach(t_format '("json")
        t_dir->join(t_format "load.il")->load()
    )
)

; END
