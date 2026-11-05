;--------------------------
; Program  : ycRegEx(load.il)
; Language : Cadence Skill
;--------------------------

; libs/load.il bootstraps ycPathLib before this file runs, so the loader
; only needs CurrentFile() and Path::load to reach every source below.
let((dir)
    dir = ycPathLib::CurrentFile()->parent()
    foreach(file '("ns.il" "core.il" "pattern.il" "match.il" "groupindex.il")
        dir->join("src" file)->load()
    )
)

; END
