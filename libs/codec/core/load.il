;--------------------------
; Program  : codec/core(load.il)
; Language : Cadence Skill
;--------------------------

; libs/load.il bootstraps ycPathLib before this file runs; this loader only
; needs currentFile() and Path::load. The two forms stay separate: the reader
; resolves 'ycCodec:::Type when reading the second form, which must happen
; after ns.il has created the namespace.
let((t_dir)
    t_dir = ycPathLib::currentFile()->parent()
    t_dir->join("src" "ns.il")->load()
)

let((t_dir)
    t_dir = ycPathLib::currentFile()->parent()
    unless(fboundp('ycCodec:::Type)
        t_dir->join("src" "sentinel.il")->load()
    )
)

; END
