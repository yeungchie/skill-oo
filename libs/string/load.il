;--------------------------
; Program  : ycString(load.il)
; Language : Cadence Skill
;--------------------------

; libs/load.il bootstraps ycPathLib before this file runs; the loader only
; needs CurrentFile() and Path::load to reach every source below.
let((dir)
    dir = ycPathLib::CurrentFile()->parent()
    foreach(file '("ns.il" "core.il" "escape.il" "naming.il" "sort.il")
        dir->join("src" file)->load()
    )
)

; END
