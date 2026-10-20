;--------------------------
; Program  : ycYaml(load.il)
; Language : Cadence Skill
;--------------------------

; libs/load.il bootstraps ycPathLib before this file runs; this loader only
; needs currentFile() and Path::load to reach every source below.
let((t_dir)
    t_dir = ycPathLib::currentFile()->parent()
    foreach(t_file '("ns.il" "yaml.il" "scalar.il" "flow.il" "block.il" "encode.il")
        t_dir->join("src" t_file)->load()
    )
)

; END
