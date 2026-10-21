ycNamespace:::require("ycCodec")

useNamespace("ycCsv")

; ---------- 记录扫描 ----------

procedure(_parseQuoted(t_s n_i n_delim "txn")  ; -> list
    ; 解析从引号开始的字段，返回字段值与下一位置（未消费分隔符/行尾）。
    ;
    ; **参数**
    ;   t_s      (str) - 输入文本
    ;   n_i      (int) - 开引号位置
    ;   n_delim  (int) - 分隔符字节码
    ;
    ; **返回**
    ;   (list) - (字段字符串 下一位置)；未闭合或闭合后有多余字符时报错
    let((n_len n_open n_run l_p g_closed n_c)
        n_len = length(t_s)
        n_open = n_i
        n_i = n_i + 1
        n_run = n_i
        while(n_i <= n_len && !g_closed
            n_c = _code(t_s n_i)
            if(n_c == 34
                progn(
                    when(n_run < n_i
                        l_p = tconc(l_p substring(t_s n_run n_i - n_run))
                    )
                    if(_code(t_s n_i + 1) == 34
                        progn(
                            l_p = tconc(l_p "\"")
                            n_i = n_i + 2
                            n_run = n_i
                        )
                        progn(
                            n_i = n_i + 1
                            g_closed = t
                        )
                    )
                )
                n_i = n_i + 1
            )
        )
        unless(g_closed
            _error(t_s n_open "unterminated quoted field")
        )
        n_c = _code(t_s n_i)
        unless(!n_c || n_c == n_delim || n_c == 10 || n_c == 13
            _error(t_s n_i "unexpected character after closing quote")
        )
        list(_build(l_p) n_i)
    )
)

procedure(_parseField(t_s n_i n_delim "txn")  ; -> list
    ; 解析一个字段（引号或裸文本），返回字段值与下一位置。
    ;
    ; **参数**
    ;   t_s      (str) - 输入文本
    ;   n_i      (int) - 字段起点
    ;   n_delim  (int) - 分隔符字节码
    ;
    ; **返回**
    ;   (list) - (字段字符串 下一位置)；裸字段内出现引号时报错
    let((n_len n_start n_c g_stop)
        n_len = length(t_s)
        if(n_i <= n_len && _code(t_s n_i) == 34
            _parseQuoted(t_s n_i n_delim)
            progn(
                n_start = n_i
                while(n_i <= n_len && !g_stop
                    n_c = _code(t_s n_i)
                    cond(
                        (n_c == n_delim || n_c == 10 || n_c == 13
                            g_stop = t
                        )
                        (n_c == 34
                            _error(t_s n_i "unexpected quote in unquoted field")
                        )
                        (t
                            n_i = n_i + 1
                        )
                    )
                )
                list(if(n_start < n_i substring(t_s n_start n_i - n_start) "") n_i)
            )
        )
    )
)

procedure(_parseRecord(t_s n_i n_delim "txn")  ; -> list
    ; 解析一条记录（字段列表），返回记录与下一位置（行尾之后）。
    ;
    ; **参数**
    ;   t_s      (str) - 输入文本
    ;   n_i      (int) - 记录起点
    ;   n_delim  (int) - 分隔符字节码
    ;
    ; **返回**
    ;   (list) - (字段列表 下一位置)
    let((l_fields l_field n_c g_done)
        while(!g_done
            l_field = _parseField(t_s n_i n_delim)
            l_fields = tconc(l_fields car(l_field))
            n_i = cadr(l_field)
            n_c = _code(t_s n_i)
            cond(
                (!n_c
                    g_done = t
                )
                (n_c == n_delim
                    n_i = n_i + 1
                )
                (t
                    if(n_c == 13 && _code(t_s n_i + 1) == 10
                        n_i = n_i + 2
                        n_i = n_i + 1
                    )
                    g_done = t
                )
            )
        )
        list(car(l_fields) n_i)
    )
)

procedure(_scanRows(t_s n_delim g_skipEmpty "tng")  ; -> list
    ; 扫描全部记录，可选跳过单空字段记录；同时保留每条记录起点。
    ;
    ; **参数**
    ;   t_s         (str) - 输入文本
    ;   n_delim     (int) - 分隔符字节码
    ;   g_skipEmpty (t|nil) - 是否跳过单空字段记录
    ;
    ; **返回**
    ;   (list) - (行列表 起点列表)，两者按记录顺序对应
    let((n_len n_i n_start l_rows l_starts l_rec l_row)
        n_len = length(t_s)
        n_i = 1
        while(n_i <= n_len
            n_start = n_i
            l_rec = _parseRecord(t_s n_i n_delim)
            l_row = car(l_rec)
            n_i = cadr(l_rec)
            unless(g_skipEmpty && length(l_row) == 1 && car(l_row) == ""
                l_rows = tconc(l_rows l_row)
                l_starts = tconc(l_starts n_start)
            )
        )
        list(car(l_rows) car(l_starts))
    )
)

procedure(_checkWidths(l_rows l_starts n_width t_s "llnt")  ; -> t
    ; 校验有表头时每条记录宽度不超过列名数。
    ;
    ; **参数**
    ;   l_rows    (list[list[str]]) - 数据行
    ;   l_starts  (list[int]) - 各行在原文中的起点
    ;   n_width   (int) - 表头列数
    ;   t_s       (str) - 原始文本（用于行列定位）
    ;
    ; **返回**
    ;   (t) - 全部合法时返回 t；超宽行以 error() 中断
    for(n_i 1 length(l_rows)
        when(n_width < length(nth(n_i - 1 l_rows))
            _error(t_s nth(n_i - 1 l_starts)
                lsprintf("row %d has %d fields but header has %d"
                    n_i length(nth(n_i - 1 l_rows)) n_width)
            )
        )
    )
    t
)

; ---------- 解码入口 ----------

procedure(decode(t_str \@key (format "csv") (header nil) (delimiter nil) (skipEmpty nil) (stripBom t) "ttgggg")  ; -> Table
    ; 解码 CSV/TSV 文本为 Table。
    ;
    ; **参数**
    ;   t_str      (str) - 输入文本
    ;   ?format    (str) - "csv"（默认）或 "tsv"，决定默认分隔符
    ;   ?header    (t|list[str]|nil) - t 取首条记录作列名；list 使用给定列名；默认 nil
    ;   ?delimiter (str) - 单字节分隔符覆盖；默认按 format 取逗号/制表符
    ;   ?skipEmpty (t|nil) - t 时跳过单空字段记录；默认 nil
    ;   ?stripBom  (t|nil) - t 时剥离开头 UTF-8 BOM；默认 t
    ;
    ; **返回**
    ;   (Table) - 解码结果；格式/选项/引号/表头宽度非法时报错
    unless(stringp(t_str)
        error("ycCsv::decode: expects a string")
    )
    let((n_delim g_header n_len t_body l_scan l_rows l_starts l_names)
        n_delim = _delimCode(delimiter _formatDelim(format "ycCsv::decode") "ycCsv::decode")
        g_header = cond(
            (header == nil nil)
            (header == t t)
            (t
                unless(listp(header)
                    error("ycCsv::decode: ?header expects t, nil, or a list of strings")
                )
                _checkHeader(header "ycCsv::decode")
            )
        )
        n_len = length(t_str)
        t_body = t_str
        when(stripBom && 3 <= n_len
                && _code(t_str 1) == 239
                && _code(t_str 2) == 187
                && _code(t_str 3) == 191
            t_body = if(3 < n_len substring(t_str 4) "")
        )
        l_scan = _scanRows(t_body n_delim skipEmpty)
        l_rows = car(l_scan)
        l_starts = cadr(l_scan)
        cond(
            (g_header == t
                if(l_rows
                    progn(
                        l_names = _checkHeader(car(l_rows) "ycCsv::decode")
                        _checkWidths(cdr(l_rows) cdr(l_starts) length(l_names) t_body)
                        Table(cdr(l_rows) ?header l_names)
                    )
                    Table(nil)
                )
            )
            (g_header
                _checkWidths(l_rows l_starts length(g_header) t_body)
                Table(l_rows ?header g_header)
            )
            (t
                Table(l_rows)
            )
        )
    )
)

unuseNamespace("ycCsv")

; END
