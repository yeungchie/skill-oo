;--------------------------
; Program  : codec/core(load.il)
; Language : Cadence Skill
;--------------------------

; libs/load.il bootstraps ycPathLib before this file runs; this loader only
; needs CurrentFile() and Path::load. The two forms stay separate: the reader
; resolves 'ycCodec:::Type when reading the second form, which must happen
; after ns.il has created the namespace.
let((dir)
    dir = ycPathLib::CurrentFile()->parent()
    dir->join("src" "ns.il")->load()
)

let((dir)
    dir = ycPathLib::CurrentFile()->parent()
    unless(fboundp('ycCodec:::Type)
        dir->join("src" "sentinel.il")->load()
    )
)

; END
