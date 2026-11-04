unless(findNamespace("ycLang")
    makeNamespace("ycLang")
)

; ycWith 宏与 __ycWithEnter__/__ycWithExit__ 通用函数是全局符号，不登记；
; 登记会把宏或方法键重绑成普通符号。
addToNamespace("ycLang"
    mapcar('symbolToString '(
        ; with.il
        _ycWithHas  ; proc
        _ycWithExpand  ; proc
    ))
)
unuseNamespace("ycLang")

; END
