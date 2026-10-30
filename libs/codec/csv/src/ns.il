unless(findNamespace("ycCsv")
    makeNamespace("ycCsv")
)
addToNamespace("ycCsv"
    mapcar('symbolToString '(
        ; table.il
        Table  ; proc, class
        TableData  ; class
        _Missing  ; proc
        _MaxWidth  ; proc

        ; decode.il
        Decode  ; proc
        _CheckWidths  ; proc
        _ParseQuoted  ; proc
        _ParseField  ; proc
        _ParseRecord  ; proc
        _ScanRows  ; proc

        ; encode.il
        Encode  ; proc
        _QuoteField  ; proc
        _RecordText  ; proc

        ; core.il
        _Code  ; proc
        _LineCol  ; proc
        _Error  ; proc
        _Build  ; proc
        _CopyRows  ; proc
        _FormatDelim  ; proc
        _DelimCode  ; proc
        _EolText  ; proc
        _CheckHeader  ; proc
        _CheckRows  ; proc
    ))
)
unuseNamespace("ycCsv")

; END
