unless(findNamespace("ycTextwrap")
    makeNamespace("ycTextwrap")
)
addToNamespace("ycTextwrap"
    mapcar('symbolToString '(
        Wrap
        Fill
        Dedent
        Indent
        Shorten
        _IsSpaceCp
        _CheckUnit
        _CpWidth
        _WidthText
        _WidthCps
        _TakeCps
        _DropCps
        _FitCount
        _CutCount
        _FirstChunk
        _WordsFromCps
        _JoinWordsCps
        _NormalizeNewlines
        _LogicalLines
        _PackCps
        _WrapCps
        _TrimTrailingSpaces
        _CutAtSpace
        _FitPlaceholder
        _ShortenCps
        _SplitAll
        _WsPrefix
        _CommonPrefix
    ))
)
unuseNamespace("ycTextwrap")

; END
