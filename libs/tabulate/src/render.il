;--------------------------
; Program  : ycTabulate(src/render.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::require("ycTextwrap" "ycUtf8")

useNamespace("ycTabulate")

; ---------- 公开入口 ----------

procedure(renderTable(l_rows \@key (headers nil) (format "simple") (align "left") (floatFmt "%g") (missingVal "") (maxColWidth nil) (unit "display") (ambiguous 1) "lgtgttgtx")  ; -> str
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
        error("ycTabulate::renderTable: rows must be a list (%A)" l_rows)
    )
    unless(headers == nil || listp(headers)
        error("ycTabulate::renderTable: headers must be a list or nil (%A)" headers)
    )
    unless(format == "plain" || format == "simple" || format == "grid" || format == "pipe"
        error("ycTabulate::renderTable: unknown format %A" format)
    )
    unless(stringp(floatFmt)
        error("ycTabulate::renderTable: floatFmt must be a string (%A)" floatFmt)
    )
    unless(stringp(missingVal)
        error("ycTabulate::renderTable: missingVal must be a string (%A)" missingVal)
    )
    unless(maxColWidth == nil || (fixp(maxColWidth) && maxColWidth >= 1)
        error("ycTabulate::renderTable: maxColWidth must be nil or a positive integer (%A)" maxColWidth)
    )
    _checkUnit("ycTabulate::renderTable" unit ambiguous)
    unless(errset(sprintf(nil floatFmt 0.0) nil)
        error("ycTabulate::renderTable: invalid floatFmt %A" floatFmt)
    )
    let((n_cols l_head l_cellRows l_aligns l_decs l_widths)
        n_cols = if(headers length(headers) if(l_rows length(car(l_rows)) 0))
        if(n_cols == 0
            ""
            progn(
        l_head = when(headers
            mapcar(
                lambda((g_cell) _cellLines(g_cell floatFmt missingVal maxColWidth unit ambiguous))
                headers
            )
        )
        l_cellRows = cons(nil nil)
        foreach(l_row l_rows
            unless(listp(l_row)
                error("ycTabulate::renderTable: row %d is not a list" length(car(l_cellRows)) + 1)
            )
            unless(length(l_row) == n_cols
                error(
                    "ycTabulate::renderTable: row %d has %d cells, expected %d"
                    length(car(l_cellRows)) + 1
                    length(l_row)
                    n_cols
                )
            )
            let((l_cells)
                l_cells = cons(nil nil)
                foreach(g_cell l_row
                    tconc(l_cells _cellLines(g_cell floatFmt missingVal maxColWidth unit ambiguous))
                )
                tconc(l_cellRows car(l_cells))
            )
        )
        l_rows = car(l_cellRows)
        when(format == "pipe"
            l_head = when(l_head
                mapcar(lambda((l_block) _pipeCell(l_block)) l_head)
            )
            l_rows = mapcar(
                lambda((l_row)
                    mapcar(lambda((l_block) _pipeCell(l_block)) l_row)
                )
                l_rows
            )
        )
        l_aligns = _normalizeAlign(align n_cols)
        l_widths = cons(nil nil)
        l_decs = cons(nil nil)
        for(n_i 0 n_cols - 1
            let((l_blocks l_dec n_w)
                l_blocks = _columnBlocks(l_head l_rows n_i)
                l_dec = when(nth(n_i l_aligns) == "decimal"
                    _decInfo(l_blocks unit ambiguous)
                )
                n_w = _colWidth(l_blocks l_dec unit ambiguous)
                when(format == "pipe" && n_w < 3
                    n_w = 3
                )
                tconc(l_widths n_w)
                tconc(l_decs l_dec)
            )
        )
        cond(
            ((format == "plain")
                _formatPlain(l_head l_rows car(l_widths) l_aligns car(l_decs) unit ambiguous)
            )
            ((format == "simple")
                _formatSimple(l_head l_rows car(l_widths) l_aligns car(l_decs) unit ambiguous)
            )
            ((format == "grid")
                _formatGrid(l_head l_rows car(l_widths) l_aligns car(l_decs) unit ambiguous)
            )
            (t
                _formatPipe(l_head l_rows car(l_widths) l_aligns car(l_decs) unit ambiguous)
            )
        )
        )
    )
)
)
unuseNamespace("ycTabulate")

; END
