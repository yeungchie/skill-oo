unless(findNamespace("ycCodec")
    makeNamespace("ycCodec")
)
addToNamespace("ycCodec"
    mapcar('symbolToString '(
        ; sentinel.il
        Type  ; proc, class
        TypeData  ; class
        True  ; var
        False  ; var
        Null  ; var
        Missing  ; var
        _TypeCache  ; var
    ))
)
unuseNamespace("ycCodec")

; END
