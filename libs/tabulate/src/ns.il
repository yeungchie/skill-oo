unless(findNamespace("ycTabulate")
    makeNamespace("ycTabulate")
)
addToNamespace("ycTabulate"
    mapcar('symbolToString '(
        ; render.il
        Render  ; proc

        ; cell.il
        _CheckUnit  ; proc
        _WidthText  ; proc
        _RepeatChar  ; proc
        _Rstrip  ; proc
        _CellText  ; proc
        _SplitCellLines  ; proc
        _CellLines  ; proc
        _EscapePipe  ; proc
        _PipeCell  ; proc
        _SplitDecimal  ; proc
        _NormalizeAlign  ; proc
        _ColumnBlocks  ; proc
        _DecInfo  ; proc
        _ColWidth  ; proc
        _PadText  ; proc
        _PadCell  ; proc

        ; format.il
        _RowLines  ; proc
        _BoxLines  ; proc
        _Border  ; proc
        _SimpleSep  ; proc
        _PipeSep  ; proc
        _FormatPlain  ; proc
        _FormatSimple  ; proc
        _FormatGrid  ; proc
        _FormatPipe  ; proc
    ))
)
unuseNamespace("ycTabulate")

; END
