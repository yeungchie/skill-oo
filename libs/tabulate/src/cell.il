;--------------------------
; Program  : ycTabulate(src/cell.il)
; Language : Cadence Skill
;--------------------------

ycNamespace:::Require("ycTextwrap" "ycUtf8")

useNamespace("ycTabulate")

; ---------- 宽度与对齐 ----------

procedure(_CheckUnit(t_ctx t_unit n_amb "ttx")  ; -> nil
    ; 校验宽度单位与 ambiguous 选项（内部实现）。
    ;
    ; **参数**
    ;   t_ctx   (str) - 错误消息上下文
    ;   t_unit  (str) - "display" 或 "char"
    ;   n_amb   (int) - 1 或 2
    ;
    ; **返回**
    ;   (nil) - 合法时无返回值；非法时报错
    unless(t_unit == "display" || t_unit == "char"
        error("%s: unknown unit %A" t_ctx t_unit)
    )
    when(t_unit == "display" && !(n_amb == 1 || n_amb == 2)
        error("%s: ambiguous must be 1 or 2" t_ctx)
    )
)

procedure(_WidthText(t_s t_unit n_amb "ttx")  ; -> int
    ; 计算字符串在指定单位下的宽度（内部实现）。
    ;
    ; **参数**
    ;   t_s    (str) - 输入串
    ;   t_unit (str) - "display" 或 "char"
    ;   n_amb  (int) - East Asian Ambiguous 宽度
    ;
    ; **返回**
    ;   (int) - 显示列宽或码点数
    if(t_unit == "char"
        ycUtf8:::CharCount(t_s)
        ycUtf8:::Width(t_s ?ambiguous n_amb)
    )
)

procedure(_RepeatChar(t_ch n_times "tx")  ; -> str
    ; 重复单字符（内部实现）。
    ;
    ; **参数**
    ;   t_ch     (str) - 单字符
    ;   n_times  (int) - 次数（>= 0）
    ;
    ; **返回**
    ;   (str) - 重复结果；0 次为空串
    let((t_res)
        t_res = ""
        when(n_times > 0
            for(n_i 1 n_times
                t_res = strcat(t_res t_ch)
            )
        )
        t_res
    )
)

procedure(_Rstrip(t_s "t")  ; -> str
    ; 去除尾部空格（内部实现）。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;
    ; **返回**
    ;   (str) - 去尾空格后的串
    let((n_end)
        n_end = length(t_s)
        while(n_end > 0 && charToInt(getchar(t_s n_end)) == 32
            n_end--
        )
        substring(t_s 1 n_end)
    )
)

; ---------- 单元格转换 ----------

procedure(_CellText(g_cell t_floatFmt t_missing "gtt")  ; -> str
    ; 将任意单元格值转为文本（内部实现）。
    ;
    ; **参数**
    ;   g_cell     (any) - 单元格值
    ;   t_floatFmt (str) - 浮点格式
    ;   t_missing  (str) - nil 的替代文本
    ;
    ; **返回**
    ;   (str) - 文本表示
    cond(
        ((g_cell == nil) t_missing)
        ((stringp g_cell) g_cell)
        ((fixp g_cell) sprintf(nil "%d" g_cell))
        ((floatp g_cell) sprintf(nil t_floatFmt g_cell))
        (t sprintf(nil "%A" g_cell))
    )
)

procedure(_SplitCellLines(t_s "t")  ; -> list[str]
    ; 按物理换行切分单元格文本；CRLF/CR 归一为 LF（内部实现）。
    ;
    ; **参数**
    ;   t_s  (str) - 输入文本
    ;
    ; **返回**
    ;   (list[str]) - 行列表；空串为 ("")
    let((l_res l_line n_i n_len n_b)
        n_i = 1
        n_len = length(t_s)
        while(n_i <= n_len
            n_b = charToInt(getchar(t_s n_i))
            if(n_b == 13
            then
                l_res = tconc(l_res buildString(car(l_line) ""))
                l_line = nil
                when(n_i < n_len && charToInt(getchar(t_s n_i + 1)) == 10
                    n_i++
                )
            else
                if(n_b == 10
                then
                    l_res = tconc(l_res buildString(car(l_line) ""))
                    l_line = nil
                else
                    l_line = tconc(l_line getchar(t_s n_i))
                )
            )
            n_i++
        )
        unless(
            t_s != ""
            && (charToInt(getchar(t_s n_len)) == 10 || charToInt(getchar(t_s n_len)) == 13)
            l_res = tconc(l_res buildString(car(l_line) ""))
        )
        car(l_res)
    )
)

procedure(_CellLines(g_cell t_floatFmt t_missing g_max t_unit n_amb "gttgtx")  ; -> list[str]
    ; 转换单元格并按需折行（内部实现）。
    ;
    ; **参数**
    ;   g_cell     (any) - 单元格值
    ;   t_floatFmt (str) - 浮点格式
    ;   t_missing  (str) - nil 的替代文本
    ;   g_max      (int|nil) - 单元格最大宽度；nil 不折行
    ;   t_unit     (str) - 单位
    ;   n_amb      (int) - Ambiguous 宽度
    ;
    ; **返回**
    ;   (list[str]) - 单元格物理行
    let((t_text l_lines)
        t_text = _CellText(g_cell t_floatFmt t_missing)
        l_lines = if(g_max
            ycTextwrap::Wrap(t_text ?width g_max ?unit t_unit ?ambiguous n_amb)
            _SplitCellLines(t_text)
        )
        if(l_lines l_lines list(""))
    )
)

procedure(_EscapePipe(t_s "t")  ; -> str
    ; 转义 Markdown 表格中的竖线（内部实现）。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;
    ; **返回**
    ;   (str) - 竖线写成 \\|
    let((l_res n_i n_len n_b)
        n_i = 1
        n_len = length(t_s)
        while(n_i <= n_len
            n_b = charToInt(getchar(t_s n_i))
            if(n_b == 124
                l_res = tconc(l_res "\\|")
                l_res = tconc(l_res getchar(t_s n_i))
            )
            n_i++
        )
        buildString(car(l_res) "")
    )
)

procedure(_PipeCell(l_lines "l")  ; -> list[str]
    ; 把多行单元格拼成单行 Markdown 文本（内部实现）。
    ;
    ; **参数**
    ;   l_lines  (list[str]) - 物理行
    ;
    ; **返回**
    ;   (list[str]) - 单元素列表
    list(buildString(mapcar(lambda((t_line) _EscapePipe(t_line)) l_lines) "<br>"))
)

procedure(_SplitDecimal(t_s "t")  ; -> list[str]
    ; 在首个句点处拆分（内部实现）。
    ;
    ; **参数**
    ;   t_s  (str) - 输入串
    ;
    ; **返回**
    ;   (list[str]) - (句点前 句点及之后)；无句点时后段为 ""
    let((n_i n_len n_b g_found)
        n_i = 1
        n_len = length(t_s)
        while(n_i <= n_len && !g_found
            n_b = charToInt(getchar(t_s n_i))
            if(n_b == 46
                g_found = t
                n_i++
            )
        )
        if(g_found
            list(
                if(n_i > 1 substring(t_s 1 n_i - 1) "")
                substring(t_s n_i length(t_s) - n_i + 1)
            )
            list(t_s "")
        )
    )
)

; ---------- 对齐与矩阵 ----------

procedure(_NormalizeAlign(g_align n_cols "gx")  ; -> list[str]
    ; 校验并展开对齐选项（内部实现）。
    ;
    ; **参数**
    ;   g_align  (str|list[str]) - 单值或逐列列表
    ;   n_cols   (int) - 列数
    ;
    ; **返回**
    ;   (list[str]) - 每列对齐方式
    let((l_res)
        if(stringp(g_align)
        then
            unless(member(g_align '("left" "right" "center" "decimal"))
                error("ycTabulate::Render: unknown align %A" g_align)
            )
            for(n_i 1 n_cols
                l_res = tconc(l_res g_align)
            )
        else
            if(listp(g_align)
            then
                unless(length(g_align) == n_cols
                    error("ycTabulate::Render: align list has %d entries for %d columns" length(g_align) n_cols)
                )
                foreach(g_item g_align
                    unless(stringp(g_item) && member(g_item '("left" "right" "center" "decimal"))
                        error("ycTabulate::Render: unknown align %A" g_item)
                    )
                    l_res = tconc(l_res g_item)
                )
            else
                error("ycTabulate::Render: align must be a string or a list (%A)" g_align)
            )
        )
        car(l_res)
    )
)

procedure(_ColumnBlocks(l_head l_rows n_col "llx")  ; -> list
    ; 收集某列的全部单元格块（内部实现）。
    ;
    ; **参数**
    ;   l_head  (list[list[str]]|nil) - 表头块
    ;   l_rows  (list[list[list[str]]]) - 行块
    ;   n_col   (int) - 0-based 列号
    ;
    ; **返回**
    ;   (list[list[str]]) - 单元格块列表
    let((l_res)
        when(l_head
            l_res = tconc(l_res nth(n_col l_head))
        )
        foreach(l_row l_rows
            l_res = tconc(l_res nth(n_col l_row))
        )
        car(l_res)
    )
)

procedure(_DecInfo(l_blocks t_unit n_amb "ltx")  ; -> list[int]
    ; 计算小数点对齐的左右最大宽度（内部实现）。
    ;
    ; **参数**
    ;   l_blocks  (list[list[str]]) - 单元格块
    ;   t_unit    (str) - 单位
    ;   n_amb     (int) - Ambiguous 宽度
    ;
    ; **返回**
    ;   (list[int]) - (左最大宽 右最大宽)
    let((n_left n_right)
        n_left = 0
        n_right = 0
        foreach(l_block l_blocks
            foreach(t_line l_block
                let((l_parts)
                    l_parts = _SplitDecimal(t_line)
                    when(_WidthText(car(l_parts) t_unit n_amb) > n_left
                        n_left = _WidthText(car(l_parts) t_unit n_amb)
                    )
                    when(_WidthText(cadr(l_parts) t_unit n_amb) > n_right
                        n_right = _WidthText(cadr(l_parts) t_unit n_amb)
                    )
                )
            )
        )
        list(n_left n_right)
    )
)

procedure(_ColWidth(l_blocks l_dec t_unit n_amb "lltx")  ; -> int
    ; 计算某列宽度（内部实现）。
    ;
    ; **参数**
    ;   l_blocks  (list[list[str]]) - 单元格块
    ;   l_dec     (list[int]|nil) - 小数点对齐信息
    ;   t_unit    (str) - 单位
    ;   n_amb     (int) - Ambiguous 宽度
    ;
    ; **返回**
    ;   (int) - 列宽
    if(l_dec
        car(l_dec) + cadr(l_dec)
        let((n_max)
            n_max = 0
            foreach(l_block l_blocks
                foreach(t_line l_block
                    when(_WidthText(t_line t_unit n_amb) > n_max
                        n_max = _WidthText(t_line t_unit n_amb)
                    )
                )
            )
            n_max
        )
    )
)

procedure(_PadText(t_s n_width t_align t_unit n_amb "txttx")  ; -> str
    ; 按左/右/中对齐补宽（内部实现）。
    ;
    ; **参数**
    ;   t_s     (str) - 文本
    ;   n_width (int) - 目标宽度
    ;   t_align (str) - "left" / "right" / "center"
    ;   t_unit  (str) - 单位
    ;   n_amb   (int) - Ambiguous 宽度
    ;
    ; **返回**
    ;   (str) - 补宽后的文本
    let((n_diff n_left n_right)
        n_diff = n_width - _WidthText(t_s t_unit n_amb)
        if(n_diff <= 0
            t_s
            cond(
                (t_align == "right"
                    strcat(_RepeatChar(" " n_diff) t_s)
                )
                (t_align == "center"
                    progn(
                        n_left = n_diff / 2
                        n_right = n_diff - n_left
                        strcat(_RepeatChar(" " n_left) t_s _RepeatChar(" " n_right))
                    )
                )
                (t
                    strcat(t_s _RepeatChar(" " n_diff))
                )
            )
        )
    )
)

procedure(_PadCell(t_line n_width t_align l_dec t_unit n_amb "txtltx")  ; -> str
    ; 按列对齐方式补宽（含小数点对齐；内部实现）。
    ;
    ; **参数**
    ;   t_line  (str) - 单元格文本
    ;   n_width (int) - 列宽
    ;   t_align (str) - 对齐方式
    ;   l_dec   (list[int]|nil) - 小数点对齐信息
    ;   t_unit  (str) - 单位
    ;   n_amb   (int) - Ambiguous 宽度
    ;
    ; **返回**
    ;   (str) - 补宽后的文本
    if(t_align == "decimal" && l_dec
        let((l_parts n_extra t_out)
            l_parts = _SplitDecimal(t_line)
            t_out = strcat(
                _RepeatChar(" " car(l_dec) - _WidthText(car(l_parts) t_unit n_amb))
                car(l_parts)
                cadr(l_parts)
                _RepeatChar(" " cadr(l_dec) - _WidthText(cadr(l_parts) t_unit n_amb))
            )
            n_extra = n_width - _WidthText(t_out t_unit n_amb)
            if(n_extra > 0 strcat(t_out _RepeatChar(" " n_extra)) t_out)
        )
        _PadText(t_line n_width t_align t_unit n_amb)
    )
)


unuseNamespace("ycTabulate")

; END
