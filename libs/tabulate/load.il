;--------------------------
; Program  : ycTabulate(load.il)
; Language : Cadence Skill
;--------------------------

let((t_dir)
    t_dir = ycPathLib::currentFile()->parent()
    foreach(t_file '("ns.il" "cell.il" "render.il" "format.il")
        t_dir->join("src" t_file)->load()
    )
)

; END
