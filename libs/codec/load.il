;--------------------------
; Program  : codec(load.il)
; Language : Cadence Skill
;--------------------------

; libs/load.il bootstraps ycPathLib before this file runs, so the loader
; only needs CurrentFile() and Path::load. core carries the shared sentinels
; and must be loaded before any format.
let((t_dir)
    t_dir = ycPathLib::CurrentFile()->parent()
    t_dir->join("core" "load.il")->load()
    foreach(t_format '("json" "yaml" "csv" "toml" "ini")
        t_dir->join(t_format "load.il")->load()
    )
)

; END
