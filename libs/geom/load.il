;--------------------------
; Program  : ycGeom(load.il)
; Language : Cadence Skill
;--------------------------

let((dir)
    dir = ycPathLib::CurrentFile()->parent()
    foreach(file '("ns.il" "internal.il" "point.il" "segment.il" "line.il" "rect.il"
                     "polygon.il" "boolean.il" "region.il" "size.il"
                     "route.il" "stroke.il" "path.il" "to_path.il")
        dir->join("src" file)->load()
    )
)

; END
