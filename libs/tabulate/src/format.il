;--------------------------
; Program  : ycTabulate(src/format.il)
; Language : Cadence Skill
;--------------------------

useNamespace("ycTabulate")

procedure(_RowLines(l_blocks l_widths l_aligns l_decs t_unit n_amb "lllltx")  ; -> list[str]
    ; 渲染一行单元格的物理行（plain / simple；内部实现）。
    ;
    ; **参数**
    ;   l_blocks  (list[list[str]]) - 单元格块
    ;   l_widths  (list[int]) - 列宽
    ;   l_aligns  (list[str]) - 对齐
    ;   l_decs    (list[list[int]]|nil) - 小数点信息
    ;   t_unit    (str) - 单位
    ;   n_amb     (int) - Ambiguous 宽度
    ;
    ; **返回**
    ;   (list[str]) - 行文本
    let((lines res line block cell)
        lines = 0
        foreach(block2 l_blocks
            when(length(block2) > lines
                lines = length(block2)
            )
        )
        for(i 0 lines - 1
            line = ""
            for(c 0 length(l_blocks) - 1
                when(c > 0 line = strcat(line "  "))
                block = nth(c l_blocks)
                cell = if(nth(i block) nth(i block) "")
                line = strcat(
                    line
                    _PadCell(
                        cell
                        nth(c l_widths)
                        nth(c l_aligns)
                        nth(c l_decs)
                        t_unit
                        n_amb
                    )
                )
            )
            res = tconc(res _Rstrip(line))
        )
        car(res)
    )
)

procedure(_BoxLines(l_blocks l_widths l_aligns l_decs t_unit n_amb "lllltx")  ; -> list[str]
    ; 渲染带竖线边框的物理行（grid / pipe；内部实现）。
    ;
    ; **参数**
    ;   l_blocks  (list[list[str]]) - 单元格块
    ;   l_widths  (list[int]) - 列宽
    ;   l_aligns  (list[str]) - 对齐
    ;   l_decs    (list[list[int]]|nil) - 小数点信息
    ;   t_unit    (str) - 单位
    ;   n_amb     (int) - Ambiguous 宽度
    ;
    ; **返回**
    ;   (list[str]) - 行文本
    let((lines res line block cell)
        lines = 0
        foreach(block2 l_blocks
            when(length(block2) > lines
                lines = length(block2)
            )
        )
        for(i 0 lines - 1
            line = "| "
            for(c 0 length(l_blocks) - 1
                when(c > 0 line = strcat(line " | "))
                block = nth(c l_blocks)
                cell = if(nth(i block) nth(i block) "")
                line = strcat(
                    line
                    _PadCell(
                        cell
                        nth(c l_widths)
                        nth(c l_aligns)
                        nth(c l_decs)
                        t_unit
                        n_amb
                    )
                )
            )
            res = tconc(res strcat(line " |"))
        )
        car(res)
    )
)

procedure(_Border(l_widths t_ch "lt")  ; -> str
    ; 生成 grid 边框线（内部实现）。
    ;
    ; **参数**
    ;   l_widths  (list[int]) - 列宽
    ;   t_ch      (str) - 横线字符 "-" 或 "="
    ;
    ; **返回**
    ;   (str) - 边框行
    let((res)
        res = "+"
        foreach(w l_widths
            res = strcat(res _RepeatChar(t_ch w + 2) "+")
        )
        res
    )
)

procedure(_SimpleSep(l_widths "l")  ; -> str
    ; 生成 simple 格式的表头分隔线（内部实现）。
    ;
    ; **参数**
    ;   l_widths  (list[int]) - 列宽
    ;
    ; **返回**
    ;   (str) - 分隔行
    let((res)
        res = ""
        for(i 0 length(l_widths) - 1
            when(i > 0 res = strcat(res "  "))
            res = strcat(res _RepeatChar("-" nth(i l_widths)))
        )
        _Rstrip(res)
    )
)

procedure(_PipeSep(l_widths l_aligns "ll")  ; -> str
    ; 生成 pipe 格式的对齐分隔行（内部实现）。
    ;
    ; **参数**
    ;   l_widths  (list[int]) - 列宽（至少 3）
    ;   l_aligns  (list[str]) - 对齐
    ;
    ; **返回**
    ;   (str) - 分隔行
    let((res mark align w)
        res = "| "
        for(i 0 length(l_widths) - 1
            when(i > 0 res = strcat(res " | "))
            w = nth(i l_widths)
            align = nth(i l_aligns)
            mark = cond(
                (align == "left" strcat(":" _RepeatChar("-" w - 1)))
                ((align == "right" || align == "decimal")
                    strcat(_RepeatChar("-" w - 1) ":")
                )
                (t strcat(":" _RepeatChar("-" w - 2) ":"))
            )
            res = strcat(res mark)
        )
        strcat(res " |")
    )
)

procedure(_FormatPlain(l_head l_rows l_widths l_aligns l_decs t_unit n_amb "llllltx")  ; -> str
    ; 渲染 plain 格式（内部实现）。
    ;
    ; **参数**
    ;   l_head    (list[list[str]]|nil) - 表头块
    ;   l_rows    (list[list[list[str]]]) - 行块
    ;   l_widths  (list[int]) - 列宽
    ;   l_aligns  (list[str]) - 对齐
    ;   l_decs    (list[list[int]]|nil) - 小数点信息
    ;   t_unit    (str) - 单位
    ;   n_amb     (int) - Ambiguous 宽度
    ;
    ; **返回**
    ;   (str) - 表格文本
    let((out)
        when(l_head
            foreach(line _RowLines(l_head l_widths l_aligns l_decs t_unit n_amb)
                out = tconc(out line)
            )
        )
        foreach(row l_rows
            foreach(line _RowLines(row l_widths l_aligns l_decs t_unit n_amb)
                out = tconc(out line)
            )
        )
        buildString(car(out) "\n")
    )
)

procedure(_FormatSimple(l_head l_rows l_widths l_aligns l_decs t_unit n_amb "llllltx")  ; -> str
    ; 渲染 simple 格式（内部实现）。
    ;
    ; **参数**
    ;   l_head    (list[list[str]]|nil) - 表头块
    ;   l_rows    (list[list[list[str]]]) - 行块
    ;   l_widths  (list[int]) - 列宽
    ;   l_aligns  (list[str]) - 对齐
    ;   l_decs    (list[list[int]]|nil) - 小数点信息
    ;   t_unit    (str) - 单位
    ;   n_amb     (int) - Ambiguous 宽度
    ;
    ; **返回**
    ;   (str) - 表格文本
    let((out)
        when(l_head
            foreach(line _RowLines(l_head l_widths l_aligns l_decs t_unit n_amb)
                out = tconc(out line)
            )
            out = tconc(out _SimpleSep(l_widths))
        )
        foreach(row l_rows
            foreach(line _RowLines(row l_widths l_aligns l_decs t_unit n_amb)
                out = tconc(out line)
            )
        )
        buildString(car(out) "\n")
    )
)

procedure(_FormatGrid(l_head l_rows l_widths l_aligns l_decs t_unit n_amb "llllltx")  ; -> str
    ; 渲染 grid 格式（内部实现）。
    ;
    ; **参数**
    ;   l_head    (list[list[str]]|nil) - 表头块
    ;   l_rows    (list[list[list[str]]]) - 行块
    ;   l_widths  (list[int]) - 列宽
    ;   l_aligns  (list[str]) - 对齐
    ;   l_decs    (list[list[int]]|nil) - 小数点信息
    ;   t_unit    (str) - 单位
    ;   n_amb     (int) - Ambiguous 宽度
    ;
    ; **返回**
    ;   (str) - 表格文本
    let((out)
        out = tconc(out _Border(l_widths "-"))
        when(l_head
            foreach(line _BoxLines(l_head l_widths l_aligns l_decs t_unit n_amb)
                out = tconc(out line)
            )
            out = tconc(out _Border(l_widths "="))
        )
        foreach(row l_rows
            foreach(line _BoxLines(row l_widths l_aligns l_decs t_unit n_amb)
                out = tconc(out line)
            )
            out = tconc(out _Border(l_widths "-"))
        )
        buildString(car(out) "\n")
    )
)

procedure(_FormatPipe(l_head l_rows l_widths l_aligns l_decs t_unit n_amb "llllltx")  ; -> str
    ; 渲染 pipe 格式（内部实现）。
    ;
    ; **参数**
    ;   l_head    (list[list[str]]|nil) - 表头块
    ;   l_rows    (list[list[list[str]]]) - 行块
    ;   l_widths  (list[int]) - 列宽（至少 3）
    ;   l_aligns  (list[str]) - 对齐
    ;   l_decs    (list[list[int]]|nil) - 小数点信息
    ;   t_unit    (str) - 单位
    ;   n_amb     (int) - Ambiguous 宽度
    ;
    ; **返回**
    ;   (str) - 表格文本
    let((out)
        when(l_head
            foreach(line _BoxLines(l_head l_widths l_aligns l_decs t_unit n_amb)
                out = tconc(out line)
            )
            out = tconc(out _PipeSep(l_widths l_aligns))
        )
        foreach(row l_rows
            foreach(line _BoxLines(row l_widths l_aligns l_decs t_unit n_amb)
                out = tconc(out line)
            )
        )
        buildString(car(out) "\n")
    )
)

unuseNamespace("ycTabulate")

; END
