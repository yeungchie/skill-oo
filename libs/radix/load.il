;--------------------------
; Program  : ycRadix(load.il)
; Language : Cadence Skill
;--------------------------

let((dir)
    dir = ycPathLib::CurrentFile()->parent()
    foreach(file '("ns.il" "radix.il")
        dir->join("src" file)->load()
    )
)

; END
