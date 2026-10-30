unless(findNamespace("ycRegEx")
    makeNamespace("ycRegEx")
)
addToNamespace("ycRegEx"
    mapcar('symbolToString '(
        ; core.il
        Compile  ; proc
        Match  ; proc
        Search  ; proc
        Fullmatch  ; proc
        Findall  ; proc
        Finditer  ; proc
        Partialp  ; proc
        Split  ; proc
        Sub  ; proc
        Subn  ; proc
        GetRecursionLimit  ; proc
        SetRecursionLimit  ; proc
        _MkPattern  ; proc
        _OptsList  ; proc
        _CompileOptsBits  ; proc
        _ExecOptsBits  ; proc
        _CompileChecked  ; proc
        _AsPat  ; proc
        _FlagsFromValue  ; proc
        _Suffix  ; proc
        _Prefix  ; proc
        _SplitBy  ; proc
        _CountSub  ; proc
        _Nth1  ; proc
        _Backref  ; proc
        _FoldCat  ; proc

        ; pattern.il
        Pattern  ; class
        PatternData  ; class
        _InstallPattern  ; proc

        ; match.il
        Matched  ; class
        MatchedData  ; class
        _WholeTemplate  ; proc
        _SplitTemplate  ; proc
        _ExtractParts  ; proc
        _PosMarker  ; proc
        _ExportMarkers  ; proc
        _ExportTemplate  ; proc
        _ExportRecords  ; proc
        _HasBit  ; proc
        _HasNumericGroupRef  ; proc
        _ShiftNumericRefs  ; proc
        _ZeroAtStart  ; proc
        _ZeroWidthRecords  ; proc
        _WalkRecords  ; proc
        _MatchStart  ; proc
        _NextMatch  ; proc
        _AnchorAt  ; proc
        _FindAllItem  ; proc
        _MkMatch  ; proc
        _GroupWhole  ; proc
        _GroupAt  ; proc
        _InstallMatch  ; proc
    ))
)
unuseNamespace("ycRegEx")

; END
