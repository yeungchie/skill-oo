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
        _IsWhitespace  ; proc
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
        _IsUpperChar  ; proc
        _IsLowerChar  ; proc
        _IsDigitChar  ; proc
        _IsWordChar  ; proc
        _CapWord  ; proc
    ))
)
unuseNamespace("ycString")

; END
