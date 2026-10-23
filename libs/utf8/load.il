;--------------------------
; Program  : ycUtf8(load.il)
; Language : Cadence Skill
;--------------------------

; libs/load.il bootstraps ycPathLib before this file runs; the loader only
; needs CurrentFile() and Path::load to reach every source below.
let((t_dir)
    t_dir = ycPathLib::CurrentFile()->parent()
    foreach(t_file '("ns.il" "utf8.il" "width-data.il" "width.il")
        t_dir->join("src" t_file)->load()
    )
)

; END
