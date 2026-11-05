;--------------------------
; Program  : ycPathLib(load.il)
; Language : Cadence Skill
;--------------------------

let((res path dir)
    res = errset(get_filename(piport) nil)
    path = when(res && car(res) && stringp(car(res)) && car(res) != ""
        car(res)
    )
    unless(path
        error("ycPathLib: can't determine the current file - load this file with an explicit path")
    )
    unless(pcreMatchp("^[~/]|^\\.{1,2}/" path)
        path = strcat("./" path)
    )
    dir = simplifyFilename(pcreReplace(pcreCompile("(?<=/)[^/]+/*$") path "" 0) t)
    unless(pcreMatchp("/$" dir)
        dir = strcat(dir "/")
    )
    unless(findNamespace("ycNamespace")
        loadi(strcat(dir "../../libs/registry.il"))
    )
    if(findNamespace("ycPathLib") == nil
        loadi(strcat(dir "../../libs/pathlib/load.il"))
        printf("ycPathLib: re-running tests with previously loaded code; restart CIW if you edited libs/pathlib/src/\n")
    )
    _TestPathlibDir = dir
)

ycNamespace:::Require("ycIO")
unless(fboundp('ycIO:::Open)
    loadi(strcat(_TestPathlibDir "../../libs/io/load.il"))
)

; load reads and evaluates one top-level form at a time; the ycJson shell
; keeps the quoted symbol below readable on a fresh CIW.
ycNamespace:::Require("ycJson")
unless(fboundp('ycJson:::Decode)
    loadi(strcat(_TestPathlibDir "../../libs/codec/json/load.il"))
)
ycNamespace:::Require("ycYaml")
unless(fboundp('ycYaml:::Decode)
    loadi(strcat(_TestPathlibDir "../../libs/codec/yaml/load.il"))
)
ycNamespace:::Require("ycCsv")
unless(fboundp('ycCsv:::Decode)
    loadi(strcat(_TestPathlibDir "../../libs/codec/csv/load.il"))
)
ycNamespace:::Require("ycToml")
unless(fboundp('ycToml:::Decode)
    loadi(strcat(_TestPathlibDir "../../libs/codec/toml/load.il"))
)
ycNamespace:::Require("ycIni")
unless(fboundp('ycIni:::Decode)
    loadi(strcat(_TestPathlibDir "../../libs/codec/ini/load.il"))
)
_TestDir = _TestPathlibDir
unless(fboundp('_TestRun)
    loadi(strcat(_TestDir "../kit.il"))
)
loadi(strcat(_TestDir "test_init.il"))

; END
