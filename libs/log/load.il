;--------------------------
; Program  : ycLog(load.il)
; Language : Cadence Skill
;--------------------------

let((dir)
    dir = ycPathLib::CurrentFile()->parent()
    foreach(file '("ns.il" "logger.il")
        dir->join("src" file)->load()
    )
)

; END
