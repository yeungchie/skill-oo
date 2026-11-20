unless(findNamespace("ycString")
    makeNamespace("ycString")
)
addToNamespace("ycString"
    mapcar('symbolToString '(
        ; core.il
        Trim  ; proc
        TrimStart  ; proc
        TrimEnd  ; proc
        Pad  ; proc
        Width  ; proc
        Split  ; proc
        Join  ; proc
        StartsWith  ; proc
        EndsWith  ; proc
        Replace  ; proc
        Count  ; proc
        _TrimSide  ; proc
        _Repeat  ; proc
        _SplitWhitespace  ; proc
        _SplitLiteral  ; proc
        _KeepNonEmpty  ; proc

        ; escape.il
        Escape  ; proc
        Unescape  ; proc

        ; naming.il
        Words  ; proc
        JoinWords  ; proc
        Sanitize  ; proc
        ToSnake  ; proc
        ToKebab  ; proc
        ToCamel  ; proc
        ToPascal  ; proc
        _IsDigitChar  ; proc
        _CapWord  ; proc

        ; sort.il
        NaturalLess  ; proc
        NaturalSort  ; proc
        _DigitRunEnd  ; proc
        _StripZeros  ; proc

        ; string.il
        String  ; proc, class
        _MkString  ; proc
        _InstallString  ; proc
    ))
)
unuseNamespace("ycString")

; END
