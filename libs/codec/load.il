;--------------------------
; Program  : codec(load.il)
; Language : Cadence Skill
;--------------------------

; libs/load.il bootstraps ycPathLib before this file runs, so the loader
; only needs CurrentFile() and Path::load. core carries the shared sentinels
; and must be loaded before any format.
let((dir)
    dir = ycPathLib::CurrentFile()->parent()
    dir->join("core" "load.il")->load()
    foreach(format '("json" "yaml" "csv" "toml" "ini")
        dir->join(format "load.il")->load()
    )
)

; END
