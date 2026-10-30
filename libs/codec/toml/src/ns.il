unless(findNamespace("ycToml")
    makeNamespace("ycToml")
)
addToNamespace("ycToml"
    mapcar('symbolToString '(
        ; decode.il
        Decode  ; proc
        _MaxDecodeDepth  ; var
        _ParseHeader  ; proc
        _ParseValue  ; proc
        _ParseArray  ; proc
        _ParseInlineTable  ; proc
        _DecodeText  ; proc

        ; encode.il
        Encode  ; proc
        _MaxEncodeDepth  ; var
        _KeyStr  ; proc
        _KeyRender  ; proc
        _PathRender  ; proc
        _EncodeString  ; proc
        _EncodeNumber  ; proc
        _EncodeValue  ; proc
        _EncodeTable  ; proc
        _TableKeys  ; proc

        ; core.il
        _Code  ; proc
        _Digitp  ; proc
        _LineCol  ; proc
        _Error  ; proc
        _Build  ; proc
        _Normalize  ; proc
        _SkipWs  ; proc
        _LineEnd  ; proc
        _PathKey  ; proc
        _MetaNew  ; proc
        _MetaSet  ; proc
        _MetaGet  ; proc
        _NewTable  ; proc
        _HasKey  ; proc
        _IsTableList  ; proc
        _MarkInline  ; proc
        _Utf8Str  ; proc
        _ValidUtf8  ; proc
        _HexVal  ; proc

        ; scalar.il
        _ReadHex  ; proc
        _ParseBasicString  ; proc
        _ParseLiteralString  ; proc
        _ParseNumber  ; proc

        ; datetime.il
        _ReadDigits  ; proc
        _LooksDate  ; proc
        _LooksTime  ; proc
        _ParseDateTime  ; proc

        ; key.il
        _ParseKeyPart  ; proc
        _ParseKeyPath  ; proc

        ; table.il
        _AssignValue  ; proc
        _HeaderTarget  ; proc
    ))
)
unuseNamespace("ycToml")

; END
