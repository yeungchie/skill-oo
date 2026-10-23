;--------------------------
; Program  : ycIni(load.il)
; Language : Cadence Skill
;--------------------------

; libs/load.il bootstraps ycPathLib before this file runs; this loader only
; needs CurrentFile() and Path::load to reach every source below.
let((t_dir)
    t_dir = ycPathLib::CurrentFile()->parent()
    t_dir->parent()->join("core" "load.il")->load()
    foreach(t_file '("ns.il" "core.il" "decode.il" "encode.il")
        t_dir->join("src" t_file)->load()
    )
)

; END
