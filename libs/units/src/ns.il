unless(findNamespace("ycUnits")
    makeNamespace("ycUnits")
)
addToNamespace("ycUnits"
    mapcar('symbolToString '(
        parse
        format
        toNumber
        toUnit
        _isWs
        _isDigit
        _hasWs
        _prefixAliases
        _shortFactor
        _prefixScale
        _tailAfter
        _prefixForExp
        _parse
    ))
)
unuseNamespace("ycUnits")

; END
