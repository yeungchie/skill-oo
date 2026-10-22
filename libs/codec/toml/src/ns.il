;--------------------------
; Program  : codec/toml(ns.il)
; Language : Cadence Skill
;--------------------------

unless(findNamespace("ycToml")
    makeNamespace("ycToml")
)
addToNamespace("ycToml"
    mapcar('symbolToString '(
        decode
        encode
        _maxDecodeDepth
        _maxEncodeDepth
        _code
        _digitp
        _lineCol
        _error
        _build
        _normalize
        _skipWs
        _lineEnd
        _pathKey
        _metaNew
        _metaSet
        _metaGet
        _newTable
        _hasKey
        _isTableList
        _markInline
        _utf8Str
        _hexVal
        _readHex
        _readDigits
        _looksDate
        _looksTime
        _parseBasicString
        _parseLiteralString
        _parseKeyPart
        _parseKeyPath
        _parseDateTime
        _parseNumber
        _parseHeader
        _parseValue
        _parseArray
        _parseInlineTable
        _assignValue
        _headerTarget
        _decodeText
        _keyStr
        _keyRender
        _pathRender
        _encodeString
        _encodeNumber
        _encodeValue
        _encodeTable
        _tableKeys
    ))
)
unuseNamespace("ycToml")

; END
