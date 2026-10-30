unless(findNamespace("ycRadix")
    makeNamespace("ycRadix")
)
addToNamespace("ycRadix"
    mapcar('symbolToString '(
        ; radix.il
        Parse  ; proc
        Format  ; proc
        Mask  ; proc
        ApplyMask  ; proc
        _DigitValue  ; proc
        _PrefixBase  ; proc
        _Mask  ; proc
    ))
)
unuseNamespace("ycRadix")

; END
