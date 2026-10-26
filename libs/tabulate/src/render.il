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
    let((n_cols n_row l_head l_cellRows l_aligns l_decs l_widths)
        n_cols = cond(
            (headers length(headers))
            (l_rows length(car(l_rows)))
            (t 0)
        )
        if(n_cols == 0
        then
            ""
        else
            l_head = when(headers
                mapcar(
                    lambda((g_cell) _CellLines(g_cell floatFmt missingVal maxColWidth unit ambiguous))
                    headers
                )
            )
            n_row = 0
            foreach(l_row l_rows
                n_row++
                unless(listp(l_row)
                    error("ycTabulate::Render: row %d is not a list" n_row)
                )
                unless(length(l_row) == n_cols
                    error(
                        "ycTabulate::Render: row %d has %d cells, expected %d"
                        n_row
                        length(l_row)
                        n_cols
                    )
                )
                let((l_cells)
                    foreach(g_cell l_row
                        l_cells = tconc(l_cells
                            _CellLines(g_cell floatFmt missingVal maxColWidth unit ambiguous))
                    )
                    l_cellRows = tconc(l_cellRows car(l_cells))
                )
            )
            l_rows = car(l_cellRows)
            when(format == "pipe"
                l_head = when(l_head
                    mapcar(lambda((l_block) _PipeCell(l_block)) l_head)
                )
                l_rows = mapcar(
                    lambda((l_row)
                        mapcar(lambda((l_block) _PipeCell(l_block)) l_row)
                    )
                    l_rows
                )
            )
            l_aligns = _NormalizeAlign(align n_cols)
            for(n_i 0 n_cols - 1
                let((l_blocks l_dec n_w)
                    l_blocks = _ColumnBlocks(l_head l_rows n_i)
                    l_dec = when(nth(n_i l_aligns) == "decimal"
                        _DecInfo(l_blocks unit ambiguous)
                    )
                    n_w = _ColWidth(l_blocks l_dec unit ambiguous)
                    when(format == "pipe" && n_w < 3
                        n_w = 3
                    )
                    l_widths = tconc(l_widths n_w)
                    l_decs = tconc(l_decs l_dec)
                )
            )
            cond(
                ((format == "plain")
                    _FormatPlain(l_head l_rows car(l_widths) l_aligns car(l_decs) unit ambiguous)
                )
                ((format == "simple")
                    _FormatSimple(l_head l_rows car(l_widths) l_aligns car(l_decs) unit ambiguous)
                )
                ((format == "grid")
                    _FormatGrid(l_head l_rows car(l_widths) l_aligns car(l_decs) unit ambiguous)
                )
                (t
                    _FormatPipe(l_head l_rows car(l_widths) l_aligns car(l_decs) unit ambiguous)
                )
            )
        )
)
)
unuseNamespace("ycTabulate")

; END
