unless(findNamespace("ycLang")
    makeNamespace("ycLang")
)

; ycWith 宏与 __ycWithEnter__/__ycWithExit__ 通用函数是全局符号，不登记；
; 登记会把宏或方法键重绑成普通符号。
addToNamespace("ycLang"
    mapcar('symbolToString '(
        ; with.il
        _ycWithHas  ; proc

        ; 跨库共享标记：值就是符号常量 ycLang::NoneArg，不做变量绑定；
        ; 其他库在缺省位与比较处写 'ycLang:::NoneArg 引用。
        NoneArg  ; sym
    ))
)
unuseNamespace("ycLang")

; END
