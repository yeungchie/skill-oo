;--------------------------
; Program  : ycGeom(load.il)
; Language : Cadence Skill
;--------------------------

let((t_dir)
    t_dir = ycPathLib::CurrentFile()->parent()
    foreach(t_file '("ns.il" "internal.il" "point.il" "segment.il" "line.il"
                     "polygon.il" "boolean.il" "region.il")
        t_dir->join("src" t_file)->load()
    )
)

; END
