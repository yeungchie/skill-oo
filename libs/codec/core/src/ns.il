;--------------------------
; Program  : codec/core(ns.il)
; Language : Cadence Skill
;--------------------------

unless(findNamespace("ycCodec")
    makeNamespace("ycCodec")
)
addToNamespace("ycCodec"
    mapcar('symbolToString '(
        Type
        TypeData
        True
        False
        Null
        Missing
        _TypeCache
    ))
)
unuseNamespace("ycCodec")

; END
