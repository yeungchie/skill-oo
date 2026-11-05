;--------------------------
; Program  : ycToml(load.il)
; Language : Cadence Skill
;--------------------------

; libs/load.il bootstraps ycPathLib before this file runs; this loader only
; needs CurrentFile() and Path::load to reach every source below.
let((dir)
    dir = ycPathLib::CurrentFile()->parent()
    dir->parent()->join("core" "load.il")->load()
    foreach(file '("ns.il" "core.il" "scalar.il" "key.il" "datetime.il" "table.il" "decode.il" "encode.il")
        dir->join("src" file)->load()
    )
)

; END
