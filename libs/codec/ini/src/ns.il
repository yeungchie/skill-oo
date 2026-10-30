unless(findNamespace("ycIni")
    makeNamespace("ycIni")
)
addToNamespace("ycIni"
    mapcar('symbolToString '(
        ; decode.il
        Decode  ; proc
        _DecodeText  ; proc
        _HeaderName  ; proc
        _KeyValue  ; proc

        ; encode.il
        Encode  ; proc
        _EmitScalar  ; proc
        _EmitSection  ; proc

        ; core.il
        _Build  ; proc
        _Code  ; proc
        _Find  ; proc
        _HasControl  ; proc
        _LineIndent  ; proc
        _Ltrim  ; proc
        _Normalize  ; proc
        _Rtrim  ; proc
        _SplitLines  ; proc
        _Trim  ; proc
        _Delim  ; proc
        _Policy  ; proc
        _Error  ; proc
        _NewTable  ; proc
        _HasKey  ; proc
        _KeyText  ; proc
        _SectionText  ; proc
        _NameText  ; proc
        _ValueText  ; proc
        _NumText  ; proc
        _TableKeys  ; proc
    ))
)
unuseNamespace("ycIni")

; END
