;--------------------------
; Program  : ycSQLite(load.il)
; Language : Cadence Skill
;--------------------------

let((dir)
    dir = ycPathLib::CurrentFile()->parent()
    dir->join("src" "ns.il")->load()
    foreach(file '("sql.il" "blob.il" "row.il" "result.il" "client.il" "database.il")
        dir->join("src" file)->load()
    )
)

; END
