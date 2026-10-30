unless(findNamespace("ycJson")
    makeNamespace("ycJson")
)
addToNamespace("ycJson"
    mapcar('symbolToString '(
        ; decode.il
        Decode  ; proc
        _MaxDecodeDepth  ; var
        _SkipWs  ; proc
        _Value  ; proc
        _Object  ; proc
        _Array  ; proc
        _DecodeText  ; proc

        ; encode.il
        Encode  ; proc
        _MaxEncodeDepth  ; var
        _KeyStr  ; proc
        _IndentStr  ; proc
        _EncodeString  ; proc
        _EncodeNumber  ; proc
        _EncodeValue  ; proc
        _EncodeList  ; proc
        _EncodeTable  ; proc

        ; core.il
        _Code  ; proc
        _Digitp  ; proc
        _LineCol  ; proc
        _Error  ; proc
        _Build  ; proc

        ; scalar.il
        _Hex4  ; proc
        _Utf8Str  ; proc
        _Literal  ; proc
        _Number  ; proc
        _String  ; proc

        ; jsonl.il
        _LineSplit  ; proc
        _LineBlankp  ; proc
        _Newlines  ; proc
    ))
)
unuseNamespace("ycJson")

; END
