;--------------------------
; Program  : ycDateTime(load.il)
; Language : Cadence Skill
;--------------------------

let((dir)
    dir = ycPathLib::CurrentFile()->parent()
    foreach(file '("ns.il" "format.il" "parse.il" "datetime.il" "timeit.il")
        dir->join("src" file)->load()
    )
)

; END
