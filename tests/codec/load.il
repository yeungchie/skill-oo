;--------------------------
; Program  : ycCodec tests(load.il)
; Language : Cadence Skill
;--------------------------
; 子套件在 let 之外加载：测试执行期间少一层局部作用域，
; 给深层嵌套用例留出调用栈余量。

let((res path dir)
    res = errset(get_filename(piport) nil)
    path = when(res && car(res) && stringp(car(res)) && car(res) != ""
        car(res)
    )
    unless(path
        error("ycCodec: can't determine the current file - load this file with an explicit path")
    )
    unless(pcreMatchp("^[~/]|^\\.{1,2}/" path)
        path = strcat("./" path)
    )
    dir = simplifyFilename(pcreReplace(pcreCompile("(?<=/)[^/]+/*$") path "" 0) t)
    unless(pcreMatchp("/$" dir)
        dir = strcat(dir "/")
    )
    _CodecTestDir = dir
)

loadi(strcat(_CodecTestDir "core/load.il"))
loadi(strcat(_CodecTestDir "json/load.il"))
loadi(strcat(_CodecTestDir "yaml/load.il"))
loadi(strcat(_CodecTestDir "csv/load.il"))
loadi(strcat(_CodecTestDir "toml/load.il"))
loadi(strcat(_CodecTestDir "ini/load.il"))

; END
