;--------------------------
; Program  : ycJson(load.il)
; Language : Cadence Skill
;--------------------------

; The codec umbrella (or libs/load.il) bootstraps ycPathLib first; this
; loader only needs currentFile() and Path::load to reach every source below.
let((t_dir)
    t_dir = ycPathLib::currentFile()->parent()
    t_dir->parent()->join("core" "load.il")->load()
    foreach(t_file '("ns.il" "json.il" "scalar.il" "decode.il" "encode.il" "jsonl.il")
        t_dir->join("src" t_file)->load()
    )
)

; END
