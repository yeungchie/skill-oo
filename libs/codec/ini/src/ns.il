;--------------------------
; Program  : codec/ini(ns.il)
; Language : Cadence Skill
;--------------------------

unless(findNamespace("ycIni")
    makeNamespace("ycIni")
)
addToNamespace("ycIni"
    mapcar('symbolToString '(
        decode
        encode
        _build
        _code
        _find
        _hasControl
        _lineIndent
        _ltrim
        _normalize
        _rtrim
        _splitLines
        _trim
        _delim
        _policy
        _error
        _newTable
        _hasKey
        _keyText
        _sectionText
        _nameText
        _valueText
        _numText
        _tableKeys
        _decodeText
        _headerName
        _keyValue
        _emitScalar
        _emitSection
    ))
)
unuseNamespace("ycIni")

; END
