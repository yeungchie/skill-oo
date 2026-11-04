;--------------------------
; Program  : ycLang(load.il)
; Language : Cadence Skill
;--------------------------

let((t_dir)
    t_dir = ycPathLib::CurrentFile()->parent()
    foreach(t_file '("ns.il" "with.il")
        t_dir->join("src" t_file)->load()
    )
)

; END
