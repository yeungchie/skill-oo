;--------------------------
; Program  : ycTabulate(src/format.il)
; Language : Cadence Skill
;--------------------------

useNamespace("ycTabulate")

procedure(_rowLines(l_blocks l_widths l_aligns l_decs t_unit n_amb "lllltx")  ; -> list[str]
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
    let((n_lines l_res t_line l_block t_cell)
        n_lines = 0
        foreach(l_block l_blocks
            when(length(l_block) > n_lines
                n_lines = length(l_block)
            )
        )
        l_res = cons(nil nil)
        for(n_i 0 n_lines - 1
            t_line = ""
            for(n_c 0 length(l_blocks) - 1
                when(n_c > 0 t_line = strcat(t_line "  "))
                l_block = nth(n_c l_blocks)
                t_cell = if(nth(n_i l_block) nth(n_i l_block) "")
                t_line = strcat(
                    t_line
                    _padCell(
                        t_cell
                        nth(n_c l_widths)
                        nth(n_c l_aligns)
                        nth(n_c l_decs)
                        t_unit
                        n_amb
                    )
                )
            )
            tconc(l_res _rstrip(t_line))
        )
        car(l_res)
    )
)

procedure(_boxLines(l_blocks l_widths l_aligns l_decs t_unit n_amb "lllltx")  ; -> list[str]
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
    let((n_lines l_res t_line l_block t_cell)
        n_lines = 0
        foreach(l_block l_blocks
            when(length(l_block) > n_lines
                n_lines = length(l_block)
            )
        )
        l_res = cons(nil nil)
        for(n_i 0 n_lines - 1
            t_line = "| "
            for(n_c 0 length(l_blocks) - 1
                when(n_c > 0 t_line = strcat(t_line " | "))
                l_block = nth(n_c l_blocks)
                t_cell = if(nth(n_i l_block) nth(n_i l_block) "")
                t_line = strcat(
                    t_line
                    _padCell(
                        t_cell
                        nth(n_c l_widths)
                        nth(n_c l_aligns)
                        nth(n_c l_decs)
                        t_unit
                        n_amb
                    )
                )
            )
            tconc(l_res strcat(t_line " |"))
        )
        car(l_res)
    )
)

procedure(_border(l_widths t_ch "lt")  ; -> str
    ; 生成 grid 边框线（内部实现）。
    ;
    ; **参数**
    ;   l_widths  (list[int]) - 列宽
    ;   t_ch      (str) - 横线字符 "-" 或 "="
    ;
    ; **返回**
    ;   (str) - 边框行
    let((t_res)
        t_res = "+"
        foreach(n_w l_widths
            t_res = strcat(t_res _repeatChar(t_ch n_w + 2) "+")
        )
        t_res
    )
)

procedure(_simpleSep(l_widths "l")  ; -> str
    ; 生成 simple 格式的表头分隔线（内部实现）。
    ;
    ; **参数**
    ;   l_widths  (list[int]) - 列宽
    ;
    ; **返回**
    ;   (str) - 分隔行
    let((t_res)
        t_res = ""
        for(n_i 0 length(l_widths) - 1
            when(n_i > 0 t_res = strcat(t_res "  "))
            t_res = strcat(t_res _repeatChar("-" nth(n_i l_widths)))
        )
        _rstrip(t_res)
    )
)

procedure(_pipeSep(l_widths l_aligns "ll")  ; -> str
    ; 生成 pipe 格式的对齐分隔行（内部实现）。
    ;
    ; **参数**
    ;   l_widths  (list[int]) - 列宽（至少 3）
    ;   l_aligns  (list[str]) - 对齐
    ;
    ; **返回**
    ;   (str) - 分隔行
    let((t_res t_mark t_align n_w)
        t_res = "| "
        for(n_i 0 length(l_widths) - 1
            when(n_i > 0 t_res = strcat(t_res " | "))
            n_w = nth(n_i l_widths)
            t_align = nth(n_i l_aligns)
            t_mark = cond(
                (t_align == "left" strcat(":" _repeatChar("-" n_w - 1)))
                ((t_align == "right" || t_align == "decimal")
                    strcat(_repeatChar("-" n_w - 1) ":")
                )
                (t strcat(":" _repeatChar("-" n_w - 2) ":"))
            )
            t_res = strcat(t_res t_mark)
        )
        strcat(t_res " |")
    )
)

procedure(_formatPlain(l_head l_rows l_widths l_aligns l_decs t_unit n_amb "llllltx")  ; -> str
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
    let((l_out)
        l_out = cons(nil nil)
        when(l_head
            foreach(t_line _rowLines(l_head l_widths l_aligns l_decs t_unit n_amb)
                tconc(l_out t_line)
            )
        )
        foreach(l_row l_rows
            foreach(t_line _rowLines(l_row l_widths l_aligns l_decs t_unit n_amb)
                tconc(l_out t_line)
            )
        )
        buildString(car(l_out) "\n")
    )
)

procedure(_formatSimple(l_head l_rows l_widths l_aligns l_decs t_unit n_amb "llllltx")  ; -> str
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
    let((l_out)
        l_out = cons(nil nil)
        when(l_head
            foreach(t_line _rowLines(l_head l_widths l_aligns l_decs t_unit n_amb)
                tconc(l_out t_line)
            )
            tconc(l_out _simpleSep(l_widths))
        )
        foreach(l_row l_rows
            foreach(t_line _rowLines(l_row l_widths l_aligns l_decs t_unit n_amb)
                tconc(l_out t_line)
            )
        )
        buildString(car(l_out) "\n")
    )
)

procedure(_formatGrid(l_head l_rows l_widths l_aligns l_decs t_unit n_amb "llllltx")  ; -> str
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
    let((l_out)
        l_out = cons(nil nil)
        tconc(l_out _border(l_widths "-"))
        when(l_head
            foreach(t_line _boxLines(l_head l_widths l_aligns l_decs t_unit n_amb)
                tconc(l_out t_line)
            )
            tconc(l_out _border(l_widths "="))
        )
        foreach(l_row l_rows
            foreach(t_line _boxLines(l_row l_widths l_aligns l_decs t_unit n_amb)
                tconc(l_out t_line)
            )
            tconc(l_out _border(l_widths "-"))
        )
        buildString(car(l_out) "\n")
    )
)

procedure(_formatPipe(l_head l_rows l_widths l_aligns l_decs t_unit n_amb "llllltx")  ; -> str
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
    let((l_out)
        l_out = cons(nil nil)
        when(l_head
            foreach(t_line _boxLines(l_head l_widths l_aligns l_decs t_unit n_amb)
                tconc(l_out t_line)
            )
            tconc(l_out _pipeSep(l_widths l_aligns))
        )
        foreach(l_row l_rows
            foreach(t_line _boxLines(l_row l_widths l_aligns l_decs t_unit n_amb)
                tconc(l_out t_line)
            )
        )
        buildString(car(l_out) "\n")
    )
)

unuseNamespace("ycTabulate")

; END
