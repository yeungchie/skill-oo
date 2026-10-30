unless(findNamespace("ycYaml")
    makeNamespace("ycYaml")
)
addToNamespace("ycYaml"
    mapcar('symbolToString '(
        ; decode.il
        Decode  ; proc
        _DecodeStream  ; proc
        _DecodeText  ; proc
        _FindKeyColon  ; proc
        _MergeInto  ; proc
        _ParseBlock  ; proc
        _ParseChild  ; proc
        _ParseMap  ; proc
        _ParseMapInto  ; proc
        _ParseSeq  ; proc
        _ParseSeqNested  ; proc
        _ParseValueText  ; proc
        _SkipIgnorable  ; proc
        _SplitDocuments  ; proc

        ; encode.il
        Encode  ; proc
        _BlockLines  ; proc
        _EncodeFlow  ; proc
        _EncodeKey  ; proc
        _EncodeScalar  ; proc
        _EncodeString  ; proc
        _IndentStr  ; proc
        _NumText  ; proc
        _PlainSafe  ; proc
        _SpecialStart  ; proc

        ; core.il
        _MaxDecodeDepth  ; var
        _MaxEncodeDepth  ; var
        _Anchors  ; var
        _ActiveAnchors  ; var
        _Blankp  ; proc
        _Build  ; proc
        _ChompCr  ; proc
        _Code  ; proc
        _ErrorLine  ; proc
        _JoinBuild  ; proc
        _LineCol  ; proc
        _LineIndent  ; proc
        _Ltrim  ; proc
        _Nth1  ; proc
        _Rtrim  ; proc
        _SplitLines  ; proc
        _StripComment  ; proc
        _Tail  ; proc
        _Utf8Str  ; proc

        ; flow.il
        _AliasValue  ; proc
        _FlowKey  ; proc
        _FlowMap  ; proc
        _FlowPrefix  ; proc
        _FlowSeq  ; proc
        _FlowSkip  ; proc
        _FlowTokenEnd  ; proc
        _FlowValue  ; proc
        _ParseKeyText  ; proc

        ; scalar.il
        _HexVal  ; proc
        _ParseBlockScalar  ; proc
        _ParseIntText  ; proc
        _ParseQuoted  ; proc
        _ParseScalarText  ; proc
        _ResolvePlain  ; proc
        _ScalarText  ; proc
        _TagValue  ; proc
    ))
)
unuseNamespace("ycYaml")

; END
