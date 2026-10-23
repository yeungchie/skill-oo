;--------------------------
; Program  : codec/toml(ns.il)
; Language : Cadence Skill
;--------------------------

unless(findNamespace("ycToml")
    makeNamespace("ycToml")
)
addToNamespace("ycToml"
    mapcar('symbolToString '(
        Decode
        Encode
        _MaxDecodeDepth
        _MaxEncodeDepth
        _Code
        _Digitp
        _LineCol
        _Error
        _Build
        _Normalize
        _SkipWs
        _LineEnd
        _PathKey
        _MetaNew
        _MetaSet
        _MetaGet
        _NewTable
        _HasKey
        _IsTableList
        _MarkInline
        _Utf8Str
        _ValidUtf8
        _HexVal
        _ReadHex
        _ReadDigits
        _LooksDate
        _LooksTime
        _ParseBasicString
        _ParseLiteralString
        _ParseKeyPart
        _ParseKeyPath
        _ParseDateTime
        _ParseNumber
        _ParseHeader
        _ParseValue
        _ParseArray
        _ParseInlineTable
        _AssignValue
        _HeaderTarget
        _DecodeText
        _KeyStr
        _KeyRender
        _PathRender
        _EncodeString
        _EncodeNumber
        _EncodeValue
        _EncodeTable
        _TableKeys
    ))
)
unuseNamespace("ycToml")

; END
