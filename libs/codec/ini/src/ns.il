;--------------------------
; Program  : codec/ini(ns.il)
; Language : Cadence Skill
;--------------------------

unless(findNamespace("ycIni")
    makeNamespace("ycIni")
)
addToNamespace("ycIni"
    mapcar('symbolToString '(
        Decode
        Encode
        _Build
        _Code
        _Find
        _HasControl
        _LineIndent
        _Ltrim
        _Normalize
        _Rtrim
        _SplitLines
        _Trim
        _Delim
        _Policy
        _Error
        _NewTable
        _HasKey
        _KeyText
        _SectionText
        _NameText
        _ValueText
        _NumText
        _TableKeys
        _DecodeText
        _HeaderName
        _KeyValue
        _EmitScalar
        _EmitSection
    ))
)
unuseNamespace("ycIni")

; END
