makeNamespace("ycUtf8")
addToNamespace("ycUtf8"
    mapcar('symbolToString '(
        decode
        encode
        charCount
        slice
        width
        charWidth
        isValid
        _next
        _read
        _encCp
        _build
        _inRanges
        _widthOf
        _wfRanges
        _aRanges
        _zeroRanges
    ))
)
unuseNamespace("ycUtf8")

; END
