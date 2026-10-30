unless(findNamespace("ycUtf8")
    makeNamespace("ycUtf8")
)
addToNamespace("ycUtf8"
    mapcar('symbolToString '(
        ; utf8.il
        Decode  ; proc
        Encode  ; proc
        CharCount  ; proc
        Slice  ; proc
        IsValid  ; proc
        _Next  ; proc
        _Read  ; proc
        _EncCp  ; proc
        _Build  ; proc

        ; width.il
        Width  ; proc
        CharWidth  ; proc
        _InRanges  ; proc
        _WidthOf  ; proc

        ; width-data.il
        _WfRanges  ; var
        _ARanges  ; var
        _ZeroRanges  ; var
    ))
)
unuseNamespace("ycUtf8")

; END
