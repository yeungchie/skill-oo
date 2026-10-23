unless(findNamespace("ycUnits")
    makeNamespace("ycUnits")
)
addToNamespace("ycUnits"
    mapcar('symbolToString '(
        Parse
        Format
        ToNumber
        ToUnit
        _IsWs
        _IsDigit
        _HasWs
        _PrefixAliases
        _ShortFactor
        _PrefixScale
        _TailAfter
        _PrefixForExp
        _Parse
    ))
)
unuseNamespace("ycUnits")

; END
