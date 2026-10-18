;--------------------------
; Program  : ycPathLib(load.il)
; Language : Cadence Skill
;--------------------------

let((t_res t_self t_dir)
    t_res = errset(get_filename(piport) nil)
    t_self = when(t_res && car(t_res) && stringp(car(t_res)) && car(t_res) != ""
        car(t_res)
    )
    unless(t_self
        error("ycPathLib: can't determine the current file - load this file with an explicit path")
    )
    unless(pcreMatchp("^[~/]|^\\.{1,2}/" t_self)
        t_self = strcat("./" t_self)
    )
    t_dir = simplifyFilename(pcreReplace(pcreCompile("(?<=/)[^/]+/*$") t_self "" 0) t)
    ; the registry is a dependency of this loader and of every cross-library
    ; reference; the entry loader loads it first, this guard covers direct loads
    when(!boundp('_ycModules)
        let((t_path)
            t_path = simplifyFilename(lsprintf("%s../registry.il" t_dir))
            unless(isFile(t_path)
                error("ycPathLib: not a valid file - %A" t_path)
            )
            load(t_path)
        )
    )
    foreach(t_file '("ns.il" "path.il" "fnmatch.il" "pure.il" "fs.il" "glob.il")
        let((t_path)
            t_path = lsprintf("%s/src/%s" t_dir t_file)
            unless(isFile(t_path)
                error("ycPathLib: not a valid file - %A" t_path)
            )
            load(t_path)
        )
    )
)

; END
