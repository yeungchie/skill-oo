unless(findNamespace("ycUtf8")
    makeNamespace("ycUtf8")
)
addToNamespace("ycUtf8"
    mapcar('symbolToString '(
        Decode
        Encode
        CharCount
        Slice
        Width
        CharWidth
        IsValid
        _Next
        _Read
        _EncCp
        _Build
        _InRanges
        _WidthOf
        _WfRanges
        _ARanges
        _ZeroRanges
    ))
)
unuseNamespace("ycUtf8")

; END
