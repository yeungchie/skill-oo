;--------------------------
; Program  : ycTextwrap(load.il)
; Language : Cadence Skill
;--------------------------

let((dir)
    dir = ycPathLib::CurrentFile()->parent()
    foreach(file '("ns.il" "measure.il" "wrap.il" "block.il")
        dir->join("src" file)->load()
    )
)

; END
