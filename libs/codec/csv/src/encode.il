useNamespace("ycCsv")

; ---------- 字段与记录输出 ----------

procedure(_quoteField(t_s n_delim g_quoteAll "tng")  ; -> str
    ; 按需给字段加引号：含分隔符、引号、CR、LF 或 quoteAll 时双写内部引号。
    ;
    ; **参数**
    ;   t_s         (str) - 字段文本
    ;   n_delim     (int) - 分隔符字节码
    ;   g_quoteAll  (t|nil) - 是否强制全部字段加引号
    ;
    ; **返回**
    ;   (str) - 可直接写入 CSV 的字段文本
    let((g_need n_len n_i n_c l_p n_run)
        n_len = length(t_s)
        g_need = g_quoteAll
        unless(g_need
            for(n_i 1 n_len
                n_c = _code(t_s n_i)
                when(n_c == n_delim || n_c == 34 || n_c == 10 || n_c == 13
                    g_need = t
                )
            )
        )
        if(!g_need
            t_s
            progn(
                n_run = 1
                for(n_i 1 n_len
                    n_c = _code(t_s n_i)
                    when(n_c == 34
                        when(n_run < n_i
                            l_p = tconc(l_p substring(t_s n_run n_i - n_run))
                        )
                        l_p = tconc(l_p "\"\"")
                        n_run = n_i + 1
                    )
                )
                when(n_run <= n_len
                    l_p = tconc(l_p substring(t_s n_run n_len - n_run + 1))
                )
                strcat("\"" _build(l_p) "\"")
            )
        )
    )
)

procedure(_recordText(l_cells n_delim g_quoteAll "lng")  ; -> str
    ; 把一行字段拼成分隔符分隔的记录文本。
    ;
    ; **参数**
    ;   l_cells     (list[str]) - 字段列表
    ;   n_delim     (int) - 分隔符字节码
    ;   g_quoteAll  (t|nil) - 是否强制全部字段加引号
    ;
    ; **返回**
    ;   (str) - 不含行尾的记录文本
    let((l_p)
        foreach(t_cell l_cells
            l_p = tconc(l_p _quoteField(t_cell n_delim g_quoteAll))
        )
        buildString(car(l_p) intToChar(n_delim))
    )
)

; ---------- 编码入口 ----------

procedure(encode(g_table \@key (format "csv") (delimiter nil) (eol "\n") (quoteAll nil) (finalNewline t) "gtgtgg")  ; -> str
    ; 把 Table 编码为 CSV/TSV 文本。
    ;
    ; **参数**
    ;   g_table       (Table) - 待编码表格
    ;   ?format       (str) - "csv"（默认）或 "tsv"，决定默认分隔符
    ;   ?delimiter    (str) - 单字节分隔符覆盖
    ;   ?eol          (str) - 行尾 "\n"（默认）或 "\r\n"
    ;   ?quoteAll     (t|nil) - t 时所有字段加引号；默认 nil
    ;   ?finalNewline (t|nil) - 非空输出末尾是否补行尾；默认 t
    ;
    ; **返回**
    ;   (str) - 编码文本；非 Table、选项非法或行宽超过表头时报错
    when(g_table == nil
        error("ycCsv::encode: expects a ycCsv::Table")
    )
    unless(classOf(g_table) == findClass('Table)
        error("ycCsv::encode: expects a ycCsv::Table, got %s"
            symbolToString(type(g_table)))
    )
    let((l_header l_rows n_delim t_eol l_lines t_line)
        l_header = g_table->header()
        l_rows = g_table->rows()
        _checkRows(l_rows "ycCsv::encode")
        when(l_header
            for(n_i 1 length(l_rows)
                when(length(l_header) < length(nth(n_i - 1 l_rows))
                    error("ycCsv::encode: row %d has %d fields but header has %d"
                        n_i length(nth(n_i - 1 l_rows)) length(l_header))
                )
            )
        )
        n_delim = _delimCode(delimiter _formatDelim(format "ycCsv::encode") "ycCsv::encode")
        t_eol = _eolText(eol)
        when(l_header
            t_line = _recordText(l_header n_delim quoteAll)
            when(!finalNewline && l_rows == nil && t_line == ""
                t_line = "\"\""
            )
            l_lines = tconc(l_lines t_line)
        )
        for(n_i 1 length(l_rows)
            t_line = _recordText(nth(n_i - 1 l_rows) n_delim quoteAll)
            when(!finalNewline && n_i == length(l_rows) && t_line == ""
                t_line = "\"\""
            )
            l_lines = tconc(l_lines t_line)
        )
        if(l_lines
            let((t_out)
                t_out = buildString(car(l_lines) t_eol)
                when(finalNewline
                    t_out = strcat(t_out t_eol)
                )
                t_out
            )
            ""
        )
    )
)

unuseNamespace("ycCsv")

; END
