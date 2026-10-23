;--------------------------
; Program  : ycTextwrap(load.il)
; Language : Cadence Skill
;--------------------------

let((t_dir)
    t_dir = ycPathLib::CurrentFile()->parent()
    foreach(t_file '("ns.il" "measure.il" "wrap.il" "block.il")
        t_dir->join("src" t_file)->load()
    )
)

; END
