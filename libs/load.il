;--------------------------
; Program  : skill-oo(libs/load.il)
; Language : Cadence Skill
;--------------------------

; Load the namespace registry first (no dependencies), then bootstrap
; ycPathLib - the loop below needs ycPathLib::CurrentFile. ycIO is a
; regular package below; Path->open resolves ycIO:::Open at call time.
let((path dir)
    path = get_filename(piport)
    unless(pcreMatchp("/" path)
        path = strcat("./" path)
    )
    dir = pcreReplace(pcreCompile("(?<=/)[^/]+/*$") path "" 0)
    load(strcat(dir "registry.il"))
    load(strcat(dir "pathlib/load.il"))
)

; pathlib stays outside the loop because the loop itself depends on it;
; every other package goes through the list below (one dir per entry,
; each must contain a load.il). Order below is not semantically required:
; regular packages resolve cross-library calls through ::: at call time.
let((dir pkgs)
    dir = ycPathLib::CurrentFile()->parent()
    pkgs = list(
        "io"
        "lang"
        "regex"
        "subprocess"
        "codec"
        "utf8"
        "string"
        "units"
        "radix"
        "geom"
        "textwrap"
        "tabulate"
        "datetime"
        "log"
    )
    foreach(pkg pkgs
        dir->join(pkg "load.il")->load()
    )
)

; END
