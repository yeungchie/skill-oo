;--------------------------
; Program  : ycIO(load.il)
; Language : Cadence Skill
;--------------------------

let((res path dir)
    res = errset(get_filename(piport) nil)
    path = when(res && car(res) && stringp(car(res)) && car(res) != ""
        car(res)
    )
    unless(path
        error("ycIO: can't determine the current file - load this file with an explicit path")
    )
    unless(pcreMatchp("^[~/]|^\\.{1,2}/" path)
        path = strcat("./" path)
    )
    dir = simplifyFilename(pcreReplace(pcreCompile("(?<=/)[^/]+/*$") path "" 0) t)
    foreach(file '("ns.il" "port.il")
        let((path2)
            path2 = lsprintf("%s/src/%s" dir file)
            unless(isFile(path2)
                error("ycIO: not a valid file - %A" path2)
            )
            load(path2)
        )
    )
)

; END
