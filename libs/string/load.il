;--------------------------
; Program  : ycString(load.il)
; Language : Cadence Skill
;--------------------------

; libs/load.il bootstraps ycPathLib before this file runs; the loader only
; needs currentFile() and Path::load to reach every source below.
let((t_dir)
    t_dir = ycPathLib::currentFile()->parent()
    foreach(t_file '("ns.il" "core.il" "escape.il" "naming.il")
        t_dir->join("src" t_file)->load()
    )
)

; END
