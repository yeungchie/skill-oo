unless(findNamespace("ycUnits")
    makeNamespace("ycUnits")
)
addToNamespace("ycUnits"
    mapcar('symbolToString '(
        ; units.il
        Parse  ; proc
        Format  ; proc
        ToNumber  ; proc
        ToUnit  ; proc
        _IsWs  ; proc
        _IsDigit  ; proc
        _HasWs  ; proc
        _PrefixAliases  ; proc
        _ShortFactor  ; proc
        _PrefixScale  ; proc
        _TailAfter  ; proc
        _PrefixForExp  ; proc
        _Parse  ; proc
    ))
)
unuseNamespace("ycUnits")

; END
