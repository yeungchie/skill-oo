unless(findNamespace("ycTextwrap")
    makeNamespace("ycTextwrap")
)
addToNamespace("ycTextwrap"
    mapcar('symbolToString '(
        wrap
        fill
        dedent
        indent
        shorten
        _isSpaceCp
        _checkUnit
        _cpWidth
        _widthText
        _widthCps
        _takeCps
        _dropCps
        _fitCount
        _cutCount
        _firstChunk
        _wordsFromCps
        _joinWordsCps
        _normalizeNewlines
        _logicalLines
        _packCps
        _wrapCps
        _trimTrailingSpaces
        _cutAtSpace
        _fitPlaceholder
        _shortenCps
        _splitAll
        _wsPrefix
        _commonPrefix
    ))
)
unuseNamespace("ycTextwrap")

; END
