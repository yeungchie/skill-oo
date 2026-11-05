;--------------------------
; Program  : ycLang(load.il)
; Language : Cadence Skill
;--------------------------

let((dir)
    dir = ycPathLib::CurrentFile()->parent()
    foreach(file '("ns.il" "with.il")
        dir->join("src" file)->load()
    )
)

; END
