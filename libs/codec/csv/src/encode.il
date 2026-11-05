useNamespace("ycCsv")

; ---------- 字段与记录输出 ----------

procedure(_QuoteField(t_s n_delim g_quoteAll "tng")  ; -> str
    ; 按需给字段加引号：含分隔符、引号、CR、LF 或 quoteAll 时双写内部引号。
    ;
    ; **参数**
    ;   t_s         (str) - 字段文本
    ;   n_delim     (int) - 分隔符字节码
    ;   g_quoteAll  (t|nil) - 是否强制全部字段加引号
    ;
    ; **返回**
    ;   (str) - 可直接写入 CSV 的字段文本
    let((need len i c p run)
        len = length(t_s)
        need = g_quoteAll
        unless(need
            for(i2 1 len
                c = _Code(t_s i2)
                when(c == n_delim || c == 34 || c == 10 || c == 13
                    need = t
                )
            )
        )
        if(!need
        then
            t_s
        else
            run = 1
            for(i2 1 len
                c = _Code(t_s i2)
                when(c == 34
                    when(run < i2
                        p = tconc(p substring(t_s run i2 - run))
                    )
                    p = tconc(p "\"\"")
                    run = i2 + 1
                )
            )
            when(run <= len
                p = tconc(p substring(t_s run len - run + 1))
            )
            strcat("\"" _Build(p) "\"")
        )
    )
)

procedure(_RecordText(l_cells n_delim g_quoteAll "lng")  ; -> str
    ; 把一行字段拼成分隔符分隔的记录文本。
    ;
    ; **参数**
    ;   l_cells     (list[str]) - 字段列表
    ;   n_delim     (int) - 分隔符字节码
    ;   g_quoteAll  (t|nil) - 是否强制全部字段加引号
    ;
    ; **返回**
    ;   (str) - 不含行尾的记录文本
    let((p)
        foreach(cell l_cells
            p = tconc(p _QuoteField(cell n_delim g_quoteAll))
        )
        buildString(car(p) intToChar(n_delim))
    )
)

; ---------- 编码入口 ----------

procedure(Encode(g_table \@key (format "csv") (delimiter nil) (eol "\n") (quoteAll nil) (finalNewline t) "gtgtgg")  ; -> str
    ; 把 Table 编码为 CSV/TSV 文本。
    ;
    ; **参数**
    ;   g_table       (Table) - 待编码表格
    ;   ?format       (str) - "csv"（默认）或 "tsv"，决定默认分隔符
    ;   ?delimiter    (str) - 单字节分隔符覆盖；默认 nil（按 format 选择）
    ;   ?eol          (str) - 行尾 "\n"（默认）或 "\r\n"
    ;   ?quoteAll     (t|nil) - t 时所有字段加引号；默认 nil
    ;   ?finalNewline (t|nil) - 非空输出末尾是否补行尾；默认 t
    ;
    ; **返回**
    ;   (str) - 编码文本；非 Table、选项非法或行宽超过表头时报错
    when(g_table == nil
        error("ycCsv::Encode: expects a ycCsv::Table")
    )
    unless(classOf(g_table) == findClass('Table)
        error("ycCsv::Encode: expects a ycCsv::Table, got %s"
            symbolToString(type(g_table)))
    )
    let((header rows delim eol2 lines line)
        header = g_table->header()
        rows = g_table->rows()
        _CheckRows(rows "ycCsv::Encode")
        when(header
            for(i 1 length(rows)
                when(length(header) < length(nth(i - 1 rows))
                    error("ycCsv::Encode: row %d has %d fields but header has %d"
                        i length(nth(i - 1 rows)) length(header))
                )
            )
        )
        delim = _DelimCode(delimiter _FormatDelim(format "ycCsv::Encode") "ycCsv::Encode")
        eol2 = _EolText(eol)
        when(header
            line = _RecordText(header delim quoteAll)
            when(!finalNewline && rows == nil && line == ""
                line = "\"\""
            )
            lines = tconc(lines line)
        )
        for(i 1 length(rows)
            line = _RecordText(nth(i - 1 rows) delim quoteAll)
            when(!finalNewline && i == length(rows) && line == ""
                line = "\"\""
            )
            lines = tconc(lines line)
        )
        if(lines
            let((out)
                out = buildString(car(lines) eol2)
                when(finalNewline
                    out = strcat(out eol2)
                )
                out
            )
            ""
        )
    )
)

unuseNamespace("ycCsv")

; END
