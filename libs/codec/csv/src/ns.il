unless(findNamespace("ycCsv")
    makeNamespace("ycCsv")
)
addToNamespace("ycCsv"
    mapcar('symbolToString '(
        Table
        TableData
        decode
        encode
        _missing
        _maxWidth
        _code
        _lineCol
        _error
        _build
        _copyRows
        _formatDelim
        _delimCode
        _eolText
        _checkHeader
        _checkRows
        _checkWidths
        _parseQuoted
        _parseField
        _parseRecord
        _scanRows
        _quoteField
        _recordText
    ))
)
unuseNamespace("ycCsv")

; END
