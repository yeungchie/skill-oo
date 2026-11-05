;--------------------------
; Program  : ycTabulate(load.il)
; Language : Cadence Skill
;--------------------------

let((dir)
    dir = ycPathLib::CurrentFile()->parent()
    foreach(file '("ns.il" "cell.il" "render.il" "format.il")
        dir->join("src" file)->load()
    )
)

; END
