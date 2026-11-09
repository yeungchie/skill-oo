unless(findNamespace("ycCodec")
    makeNamespace("ycCodec")
)
addToNamespace("ycCodec"
    mapcar('symbolToString '(
        ; sentinel.il
        Type  ; proc, class
        _TypeData  ; class
        True  ; var
        False  ; var
        Null  ; var
        Missing  ; var
        _TypeCache  ; var
        _TypeCanon  ; proc
        _TypeClaim  ; proc
    ))
)
unuseNamespace("ycCodec")

; END
