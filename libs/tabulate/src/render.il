;--------------------------
; Program  : ycTabulate(src/render.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::Require("ycTextwrap" "ycUtf8")

useNamespace("ycTabulate")

; ---------- 公开入口 ----------

procedure(Render(l_rows \@key (headers nil) (format "simple") (align "left") (floatFmt "%g") (missingVal "") (maxColWidth nil) (unit "display") (ambiguous 1) "lgtgttgtx")  ; -> str
    ; 将行数据渲染为文本表格。
    ;
    ; **参数**
    ;   l_rows       (list[list[any]]|nil) - 行数据
    ;   ?headers     (list[any]|nil) - 表头单元格；nil 无表头
    ;   ?format      (str) - "plain" / "simple"（默认）/ "grid" / "pipe"
    ;   ?align       (str|list[str]) - 单值或逐列对齐；默认 "left"
    ;   ?floatFmt    (str) - 浮点格式；默认 "%g"
    ;   ?missingVal  (str) - nil 单元格的替代文本；默认 ""
    ;   ?maxColWidth (int|nil) - 单元格折行宽度；nil 不折行
    ;   ?unit        (str) - "display"（默认）或 "char"
    ;   ?ambiguous   (int) - East Asian Ambiguous 宽度（1 或 2）；默认 1
    ;
    ; **返回**
    ;   (str) - 表格文本；无列时为空串
    unless(l_rows == nil || listp(l_rows)
        error("ycTabulate::Render: rows must be a list (%A)" l_rows)
    )
    unless(headers == nil || listp(headers)
        error("ycTabulate::Render: headers must be a list or nil (%A)" headers)
    )
    unless(format == "plain" || format == "simple" || format == "grid" || format == "pipe"
        error("ycTabulate::Render: unknown format %A" format)
    )
    unless(stringp(floatFmt)
        error("ycTabulate::Render: floatFmt must be a string (%A)" floatFmt)
    )
    unless(stringp(missingVal)
        error("ycTabulate::Render: missingVal must be a string (%A)" missingVal)
    )
    unless(maxColWidth == nil || (fixp(maxColWidth) && maxColWidth >= 1)
        error("ycTabulate::Render: maxColWidth must be nil or a positive integer (%A)" maxColWidth)
    )
    _CheckUnit("ycTabulate::Render" unit ambiguous)
    unless(errset(sprintf(nil floatFmt 0.0) nil)
        error("ycTabulate::Render: invalid floatFmt %A" floatFmt)
    )
    let((cols row head cellRows aligns decs widths)
        cols = cond(
            (headers length(headers))
            (l_rows length(car(l_rows)))
            (t 0)
        )
        if(cols == 0
        then
            ""
        else
            head = when(headers
                mapcar(
                    lambda((g_cell) _CellLines(g_cell floatFmt missingVal maxColWidth unit ambiguous))
                    headers
                )
            )
            row = 0
            foreach(row2 l_rows
                row++
                unless(listp(row2)
                    error("ycTabulate::Render: row %d is not a list" row)
                )
                unless(length(row2) == cols
                    error(
                        "ycTabulate::Render: row %d has %d cells, expected %d"
                        row
                        length(row2)
                        cols
                    )
                )
                let((cells)
                    foreach(cell row2
                        cells = tconc(cells
                            _CellLines(cell floatFmt missingVal maxColWidth unit ambiguous))
                    )
                    cellRows = tconc(cellRows car(cells))
                )
            )
            l_rows = car(cellRows)
            when(format == "pipe"
                head = when(head
                    mapcar(lambda((l_block) _PipeCell(l_block)) head)
                )
                l_rows = mapcar(
                    lambda((l_row)
                        mapcar(lambda((l_block) _PipeCell(l_block)) l_row)
                    )
                    l_rows
                )
            )
            aligns = _NormalizeAlign(align cols)
            for(i 0 cols - 1
                let((blocks dec w)
                    blocks = _ColumnBlocks(head l_rows i)
                    dec = when(nth(i aligns) == "decimal"
                        _DecInfo(blocks unit ambiguous)
                    )
                    w = _ColWidth(blocks dec unit ambiguous)
                    when(format == "pipe" && w < 3
                        w = 3
                    )
                    widths = tconc(widths w)
                    decs = tconc(decs dec)
                )
            )
            cond(
                ((format == "plain")
                    _FormatPlain(head l_rows car(widths) aligns car(decs) unit ambiguous)
                )
                ((format == "simple")
                    _FormatSimple(head l_rows car(widths) aligns car(decs) unit ambiguous)
                )
                ((format == "grid")
                    _FormatGrid(head l_rows car(widths) aligns car(decs) unit ambiguous)
                )
                (t
                    _FormatPipe(head l_rows car(widths) aligns car(decs) unit ambiguous)
                )
            )
        )
)
)
unuseNamespace("ycTabulate")

; END
