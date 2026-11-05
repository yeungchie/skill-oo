;--------------------------
; Program  : ycJson(load.il)
; Language : Cadence Skill
;--------------------------

; The codec umbrella (or libs/load.il) bootstraps ycPathLib first; this
; loader only needs CurrentFile() and Path::load to reach every source below.
let((dir)
    dir = ycPathLib::CurrentFile()->parent()
    dir->parent()->join("core" "load.il")->load()
    foreach(file '("ns.il" "core.il" "scalar.il" "decode.il" "encode.il" "jsonl.il")
        dir->join("src" file)->load()
    )
)

; END
