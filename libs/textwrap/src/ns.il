unless(findNamespace("ycTextwrap")
    makeNamespace("ycTextwrap")
)
addToNamespace("ycTextwrap"
    mapcar('symbolToString '(
        ; wrap.il
        Wrap  ; proc
        Fill  ; proc
        _PackCps  ; proc
        _WrapCps  ; proc
        _TrimTrailingSpaces  ; proc
        _CutAtSpace  ; proc
        _FitPlaceholder  ; proc
        _ShortenCps  ; proc

        ; block.il
        Dedent  ; proc
        Indent  ; proc
        Shorten  ; proc
        _SplitAll  ; proc
        _WsPrefix  ; proc
        _CommonPrefix  ; proc

        ; measure.il
        _IsSpaceCp  ; proc
        _CheckUnit  ; proc
        _CpWidth  ; proc
        _WidthText  ; proc
        _WidthCps  ; proc
        _TakeCps  ; proc
        _DropCps  ; proc
        _FitCount  ; proc
        _CutCount  ; proc
        _FirstChunk  ; proc
        _WordsFromCps  ; proc
        _JoinWordsCps  ; proc
        _NormalizeNewlines  ; proc
        _LogicalLines  ; proc
    ))
)
unuseNamespace("ycTextwrap")

; END
